module PatientImport
  module Normalizers
    module PostalCode
      CANADIAN_POSTAL_CODE = /\A[ABCEGHJ-NPRSTVXY]\d[ABCEGHJ-NPRSTV-Z]\d[ABCEGHJ-NPRSTV-Z]\d\z/

      def self.call(text)
        compact = text.upcase.gsub(/[\s\-]/, "")
        compact.match?(CANADIAN_POSTAL_CODE) ? Result.ok("#{compact[0, 3]} #{compact[3, 3]}") : Result.issue("invalid_postal_code")
      end
    end
  end
end
