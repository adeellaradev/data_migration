module PatientImport
  module Normalizers
    module AddressLine
      def self.call(text)
        Result.ok(text)
      end
    end
  end
end
