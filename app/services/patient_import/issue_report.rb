module PatientImport
  class IssueReport
    FORMULA_PREFIXES = [ "=", "+", "-", "@", "\t", "\r" ].freeze
    LEADING_COLUMNS = [ "row number", "outcome", "errors", "warnings" ].freeze

    def initialize(data_migration)
      @data_migration = data_migration
    end

    def filename
      "migration-#{@data_migration.id}-issues.csv"
    end

    def rows
      @rows ||= @data_migration.rows.select { |row| row.outcome == "rejected" || row.issues.any? }
    end

    def to_csv
      original_columns = rows.flat_map { |row| row.raw_data.to_h.keys }.uniq

      CSV.generate do |csv|
        csv << LEADING_COLUMNS + original_columns
        rows.each do |row|
          raw = row.raw_data.to_h
          csv << [
            row.row_number,
            row.outcome,
            codes(row.errors_list),
            codes(row.warnings),
            *original_columns.map { |column| safe_cell(raw[column]) }
          ]
        end
      end
    end

    private
      def codes(issues)
        issues.map { |issue| issue["code"] }.uniq.join("; ")
      end

      def safe_cell(value)
        text = value.to_s
        text.start_with?(*FORMULA_PREFIXES) ? "'#{text}" : text
      end
  end
end
