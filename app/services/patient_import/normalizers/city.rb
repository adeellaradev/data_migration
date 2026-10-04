module PatientImport
  module Normalizers
    module City
      def self.call(text)
        return Result.ok(text) unless text == text.downcase || text == text.upcase

        Result.ok(text.downcase.gsub(/(\A|[\s\-])(\p{L})/) { "#{$1}#{$2.upcase}" })
      end
    end
  end
end
