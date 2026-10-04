module PatientImport
  class RowNormalizer
    IDENTITY_FIELDS = %w[health_number health_number_province].freeze
    EXPECTED_FIELDS = %w[email phone address_line1 postal_code date_of_birth].freeze

    FIELD_NORMALIZERS = {
      "health_number" => Normalizers::HealthNumber,
      "health_number_province" => Normalizers::ProvinceCode,
      "first_name" => Normalizers::Name,
      "middle_name" => Normalizers::Name,
      "last_name" => Normalizers::Name,
      "date_of_birth" => Normalizers::DateOfBirth,
      "sex" => Normalizers::Sex,
      "email" => Normalizers::Email,
      "phone" => Normalizers::Phone,
      "address_line1" => Normalizers::AddressLine,
      "address_line2" => Normalizers::AddressLine,
      "city" => Normalizers::City,
      "address_province" => Normalizers::ProvinceCode,
      "postal_code" => Normalizers::PostalCode
    }.freeze

    CONFIG_AWARE = [ Normalizers::ProvinceCode, Normalizers::Sex ].freeze

    Result = Data.define(:attributes, :issues, :reformatted_fields) do
      def rejected?
        issues.any?(&:error?)
      end

      def key
        attributes.values_at("health_number_province", "health_number")
      end
    end

    def initialize(column_map:, config: Config.current)
      @column_map = column_map
      @config = config
    end

    def call(row)
      attributes = {}
      issues = []
      reformatted = []

      FIELD_NORMALIZERS.each do |field, normalizer|
        raw = @column_map[field] && row[@column_map[field]]
        text = Normalizers::Text.clean(raw, config: @config)

        if text.nil?
          issues << missing_issue(field) if IDENTITY_FIELDS.include?(field) || EXPECTED_FIELDS.include?(field)
          next
        end

        result = CONFIG_AWARE.include?(normalizer) ? normalizer.call(text, config: @config) : normalizer.call(text)
        attributes[field] = result.value unless result.value.nil?
        issues << Issue.new(field: field, code: result.issue_code, severity: severity_for(field)) if result.issue_code
        reformatted << field if !result.value.nil? && result.value.to_s != raw.to_s.strip
      end

      issues.concat(cross_field_issues(attributes))
      Result.new(attributes: attributes, issues: issues, reformatted_fields: reformatted)
    end

    private
      def severity_for(field)
        IDENTITY_FIELDS.include?(field) ? Issue::ERROR : Issue::WARNING
      end

      def missing_issue(field)
        Issue.new(field: field, code: "missing_#{field}", severity: severity_for(field))
      end

      def cross_field_issues(attributes)
        issues = []

        format = @config.health_number_format(attributes["health_number_province"])
        if format && attributes["health_number"] && !format.match?(attributes["health_number"])
          issues << Issue.new(field: "health_number", code: "health_number_format", severity: Issue::WARNING)
        end

        postal_code, address_province = attributes.values_at("postal_code", "address_province")
        if postal_code && address_province && !::Province.postal_code_matches?(address_province, postal_code)
          issues << Issue.new(field: "postal_code", code: "postal_province_mismatch", severity: Issue::WARNING)
        end

        if attributes["email"] && attributes["last_name"] && !email_mentions_last_name?(attributes["email"], attributes["last_name"])
          issues << Issue.new(field: "email", code: "email_name_mismatch", severity: Issue::WARNING)
        end

        issues
      end

      def email_mentions_last_name?(email, last_name)
        local_part = Config.lookup_key(email.split("@").first)
        surname = Config.lookup_key(last_name)
        surname.empty? || local_part.include?(surname)
      end
  end
end
