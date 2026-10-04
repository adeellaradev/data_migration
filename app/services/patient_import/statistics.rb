module PatientImport
  class Statistics
    ACCEPTED_OUTCOMES = %w[created updated unchanged].freeze

    def initialize(entries:, outcomes:, changed_fields:, column_map:, timings_ms:, config: Config.current)
      @entries = entries
      @outcomes = outcomes
      @changed_fields = changed_fields
      @column_map = column_map
      @timings_ms = timings_ms
      @config = config
    end

    def to_h
      {
        "summary" => summary,
        "timings_ms" => @timings_ms,
        "rejection_reasons" => rejection_reasons,
        "issues" => issues,
        "completeness" => completeness,
        "reformatted" => accepted_entries.flat_map { |entry| entry.result.reformatted_fields }.tally,
        "changes" => @changed_fields.flatten.tally,
        "distributions" => distributions,
        "patients_total_after" => Patient.count
      }
    end

    private
      def accepted_entries
        @accepted_entries ||= @entries.select.with_index { |_, index| ACCEPTED_OUTCOMES.include?(@outcomes[index]) }
      end

      def summary
        {
          "accepted_rows" => accepted_entries.size,
          "acceptance_rate" => percent(accepted_entries.size, @entries.size),
          "rows_without_issues" => @entries.count { |entry| entry.result.issues.empty? }
        }
      end

      def rejection_reasons
        @entries.flat_map { |entry| entry.result.issues.select(&:error?).map(&:code).uniq }.tally
      end

      def issues
        @entries.each_with_object({}) do |entry, by_code|
          entry.result.issues.group_by(&:code).each do |code, row_issues|
            by_code[code] ||= { "severity" => row_issues.first.severity, "fields" => [], "rows" => 0 }
            by_code[code]["fields"] |= row_issues.map(&:field)
            by_code[code]["rows"] += 1
          end
        end
      end

      def completeness
        total = accepted_entries.size

        Patient::MIGRATABLE_ATTRIBUTES.index_with do |field|
          in_file = accepted_entries.count { |entry| filled_in_file?(entry, field) }
          valid = accepted_entries.count { |entry| !entry.result.attributes[field].nil? }

          {
            "in_file" => in_file,
            "in_file_percent" => percent(in_file, total),
            "valid" => valid,
            "valid_percent" => percent(valid, total)
          }
        end
      end

      def filled_in_file?(entry, field)
        header = @column_map[field]
        header.present? && Normalizers::Text.clean(entry.raw[header], config: @config).present?
      end

      def distributions
        {
          "health_number_province" => accepted_entries.map { |entry| entry.result.attributes["health_number_province"] }.tally,
          "sex" => accepted_entries.map { |entry| entry.result.attributes["sex"] || "not provided" }.tally
        }
      end

      def percent(part, whole)
        return if whole.zero?

        (part * 100.0 / whole).round(1)
      end
  end
end
