module PatientImport
  class Runner
    WRITE_LOCK_KEY = 72_616_001
    WRITE_ATTEMPTS = 2

    INTERRUPTED_MESSAGE = "The migration was interrupted before it finished. Rows written before the interruption are kept; upload the file again to complete it."

    class FileError < StandardError; end

    Entry = Data.define(:row_number, :raw, :result)

    def initialize(data_migration, config: Config.current)
      @data_migration = data_migration
      @config = config
    end

    def call
      return unless claim

      status, error_message = import
      purge_source_file
      finish(status, error_message: error_message)
    end

    def abandon
      purge_source_file
      finish("failed", error_message: INTERRUPTED_MESSAGE)
    end

    private
      def claim
        claimed = DataMigration.where(id: @data_migration.id, status: "pending")
          .update_all(status: "running", started_at: Time.current, updated_at: Time.current)
        @data_migration.reload if claimed == 1
      end

      def import
        timings_ms = {}

        table = timed(timings_ms, "read") { read_csv }
        header_check = HeaderCheck.call(table.headers.compact, config: @config)
        record_headers(header_check)
        raise FileError, missing_columns_message(header_check) unless header_check.valid?

        entries = timed(timings_ms, "clean") { normalize(table, header_check) }
        winning_index = winning_index_by_key(entries)

        written = timed(timings_ms, "write") do
          with_write_lock do
            entries.each_with_index.map do |entry, index|
              superseded = !entry.result.rejected? && winning_index[entry.result.key] != index
              write(entry, superseded: superseded)
            end
          end
        end

        record_statistics(Statistics.new(
          entries: entries,
          outcomes: written.map(&:first),
          changed_fields: written.map(&:last),
          column_map: header_check.column_map,
          timings_ms: timings_ms,
          config: @config
        ))

        [ "completed", nil ]
      rescue FileError => e
        [ "failed", e.message ]
      rescue StandardError => e
        log_failure(e)
        [ "failed", "Unexpected error (#{e.class}). Rows written before the error are kept; re-running the file is safe." ]
      end

      def read_csv
        content = @data_migration.source_file.download.force_encoding(Encoding::UTF_8).delete_prefix("﻿")
        raise FileError, "The file is not valid UTF-8 text." unless content.valid_encoding?

        CSV.parse(content, headers: true)
      rescue CSV::MalformedCSVError => e
        raise FileError, "The CSV is malformed: #{e.message}"
      end

      def record_headers(header_check)
        @data_migration.update!(stats: @data_migration.stats.merge(
          "headers" => {
            "mapped" => header_check.column_map,
            "missing_required" => header_check.missing_required,
            "unknown" => header_check.unknown_headers,
            "duplicate" => header_check.duplicate_headers
          }
        ))
      end

      def record_statistics(statistics)
        @data_migration.update!(stats: @data_migration.stats.merge(statistics.to_h))
      end

      def timed(timings_ms, phase)
        started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        result = yield
        timings_ms[phase] = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000).round
        result
      end

      def missing_columns_message(header_check)
        details = header_check.missing_required.map do |field|
          "#{field.humanize} (expected one of: #{@config.headers_for(field).join(", ")})"
        end
        "Missing required columns: #{details.join("; ")}"
      end

      def normalize(table, header_check)
        normalizer = RowNormalizer.new(column_map: header_check.column_map, config: @config)

        table.each.with_index(2).filter_map do |row, row_number|
          next if row.fields.all?(&:blank?)

          raw = row.to_h
          Entry.new(row_number: row_number, raw: raw, result: normalizer.call(raw))
        end
      end

      def winning_index_by_key(entries)
        entries.each_with_index.with_object({}) do |(entry, index), winners|
          winners[entry.result.key] = index unless entry.result.rejected?
        end
      end

      def with_write_lock
        connection = ActiveRecord::Base.connection
        connection.execute("SELECT pg_advisory_lock(#{WRITE_LOCK_KEY})")
        yield
      ensure
        connection&.execute("SELECT pg_advisory_unlock(#{WRITE_LOCK_KEY})")
      end

      def write(entry, superseded:)
        attempts = 0

        begin
          attempts += 1
          ActiveRecord::Base.transaction do
            outcome, patient, changes = resolve(entry, superseded: superseded)

            @data_migration.rows.create!(
              row_number: entry.row_number,
              outcome: outcome,
              patient: patient,
              raw_data: entry.raw,
              changed_fields: changes,
              issues: entry.result.issues.map(&:to_h)
            )

            [ outcome, changes.keys ]
          end
        rescue ActiveRecord::RecordNotUnique
          retry if attempts < WRITE_ATTEMPTS
          raise
        end
      end

      def resolve(entry, superseded:)
        return [ "rejected", nil, {} ] if entry.result.rejected?
        return [ "duplicate", nil, {} ] if superseded

        attributes = entry.result.attributes
        patient = Patient.find_or_initialize_by(attributes.slice("health_number_province", "health_number"))
        patient.assign_attributes(attributes.slice(*Patient::MIGRATABLE_ATTRIBUTES).compact)

        if patient.new_record?
          patient.update!(created_by_migration: @data_migration, last_changed_by_migration: @data_migration)
          [ "created", patient, {} ]
        elsif patient.changed?
          changes = patient.changes.transform_values { |old_value, new_value| [ old_value&.to_s, new_value&.to_s ] }
          patient.update!(last_changed_by_migration: @data_migration)
          [ "updated", patient, changes ]
        else
          [ "unchanged", patient, {} ]
        end
      end

      def purge_source_file
        return unless @data_migration.source_file.attached?

        @data_migration.source_file.purge
        @data_migration.update!(source_file_purged_at: Time.current)
      rescue StandardError => e
        log_failure(e)
      end

      def finish(status, error_message: nil)
        counts = @data_migration.rows.unscope(:order).group(:outcome).count
        warning_rows = @data_migration.rows.where("issues @> ?", [ { severity: Issue::WARNING } ].to_json).count

        @data_migration.update!(
          status: status,
          finished_at: Time.current,
          error_message: error_message,
          total_rows: counts.values.sum,
          created_count: counts.fetch("created", 0),
          updated_count: counts.fetch("updated", 0),
          unchanged_count: counts.fetch("unchanged", 0),
          rejected_count: counts.fetch("rejected", 0),
          duplicate_count: counts.fetch("duplicate", 0),
          rows_with_warnings_count: warning_rows
        )
      end

      def log_failure(error)
        Rails.logger.error("PatientImport::Runner failed for data migration #{@data_migration.id}: #{error.class}\n#{error.backtrace&.first(10)&.join("\n")}")
      end
  end
end
