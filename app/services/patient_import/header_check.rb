module PatientImport
  class HeaderCheck
    Result = Data.define(:column_map, :missing_required, :unknown_headers, :duplicate_headers) do
      def valid?
        missing_required.empty?
      end
    end

    def self.normalize(header)
      header.to_s.delete_prefix("﻿").gsub(/[[:space:]_]+/, " ").strip.downcase
    end

    def self.call(headers, config: Config.current)
      column_map = {}
      unknown = []
      duplicates = []

      headers.each do |header|
        field = config.field_for_header(normalize(header))
        if field.nil?
          unknown << header
        elsif column_map.key?(field)
          duplicates << header
        else
          column_map[field] = header
        end
      end

      Result.new(
        column_map: column_map,
        missing_required: config.required_columns - column_map.keys,
        unknown_headers: unknown,
        duplicate_headers: duplicates
      )
    end
  end
end
