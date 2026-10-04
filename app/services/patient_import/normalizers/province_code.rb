module PatientImport
  module Normalizers
    module ProvinceCode
      def self.call(text, config: Config.current)
        code = config.province_code(text)
        code ? Result.ok(code) : Result.issue("unrecognized_province")
      end
    end
  end
end
