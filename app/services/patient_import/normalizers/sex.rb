module PatientImport
  module Normalizers
    module Sex
      def self.call(text, config: Config.current)
        sex = config.sex_for(text)
        sex ? Result.ok(sex) : Result.issue("unrecognized_sex", value: "unknown")
      end
    end
  end
end
