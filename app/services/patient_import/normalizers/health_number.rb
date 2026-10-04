module PatientImport
  module Normalizers
    module HealthNumber
      def self.call(text)
        Result.ok(text.gsub(/[\s\-.]/, "").upcase)
      end
    end
  end
end
