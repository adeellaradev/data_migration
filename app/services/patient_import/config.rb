module PatientImport
  class Config
    class Invalid < StandardError; end

    def self.current
      @current ||= new(Rails.application.config_for(:data_migration).to_h.deep_stringify_keys)
    end

    def self.reload!
      @current = nil
      current
    end

    def self.lookup_key(value)
      I18n.transliterate(value.to_s).downcase.gsub(/[^a-z0-9]/, "")
    end

    attr_reader :required_columns

    def initialize(settings)
      @columns = settings.fetch("columns", {})
      @required_columns = Array(settings["required_columns"])
      @placeholders = Array(settings["placeholders"]).map { |p| p.to_s.strip.downcase }.to_set
      @province_aliases = settings.fetch("province_aliases", {})
      @sex_values = settings.fetch("sex_values", {})
      @health_number_formats = settings.fetch("health_number_formats", {})
      validate!
      build_lookups
    end

    def field_for_header(header)
      @fields_by_header[header]
    end

    def placeholder?(text)
      @placeholders.include?(text.downcase)
    end

    def province_code(text)
      @provinces_by_key[self.class.lookup_key(text)]
    end

    def sex_for(text)
      @sexes_by_key[self.class.lookup_key(text)]
    end

    def health_number_format(province_code)
      @formats[province_code]
    end

    private
      def validate!
        problems = []

        unknown_fields = @columns.keys - Patient::MIGRATABLE_ATTRIBUTES
        problems << "columns: unknown fields #{unknown_fields.join(", ")}" if unknown_fields.any?
        @columns.each { |field, headers| problems << "columns: #{field} has no headers" if Array(headers).empty? }

        all_headers = @columns.values.flatten.map { |h| HeaderCheck.normalize(h) }
        repeated = all_headers.tally.select { |_, count| count > 1 }.keys
        problems << "columns: headers used for more than one field: #{repeated.join(", ")}" if repeated.any?

        missing_required = @required_columns - @columns.keys
        problems << "required_columns: not defined in columns: #{missing_required.join(", ")}" if missing_required.any?

        bad_provinces = (@province_aliases.keys + @health_number_formats.keys) - Province::CODES
        problems << "unknown province codes: #{bad_provinces.uniq.join(", ")}" if bad_provinces.any?

        bad_sexes = @sex_values.keys - Patient::SEXES
        problems << "sex_values: unknown values #{bad_sexes.join(", ")}" if bad_sexes.any?

        @health_number_formats.each do |code, pattern|
          Regexp.new(pattern)
        rescue RegexpError => e
          problems << "health_number_formats: #{code} is not a valid pattern (#{e.message})"
        end

        raise Invalid, "config/data_migration.yml is invalid:\n- #{problems.join("\n- ")}" if problems.any?
      end

      def build_lookups
        @fields_by_header = @columns.flat_map { |field, headers| Array(headers).map { |h| [ HeaderCheck.normalize(h), field ] } }.to_h

        @provinces_by_key = {}
        Province::NAMES.each do |code, name|
          [ code, name, *@province_aliases[code] ].each { |v| @provinces_by_key[self.class.lookup_key(v)] = code }
        end

        @sexes_by_key = @sex_values.flat_map { |sex, values| Array(values).map { |v| [ self.class.lookup_key(v), sex ] } }.to_h
        @formats = @health_number_formats.transform_values { |pattern| Regexp.new(pattern) }
      end
  end
end
