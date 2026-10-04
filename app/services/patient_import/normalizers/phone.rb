module PatientImport
  module Normalizers
    module Phone
      NORTH_AMERICAN_NUMBER = /\A[2-9]\d{2}[2-9]\d{6}\z/

      def self.call(text)
        digits = text.gsub(/\D/, "")
        digits = digits.delete_prefix("1") if digits.length == 11
        digits.match?(NORTH_AMERICAN_NUMBER) ? Result.ok("+1#{digits}") : Result.issue("invalid_phone")
      end
    end
  end
end
