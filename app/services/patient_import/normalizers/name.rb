module PatientImport
  module Normalizers
    module Name
      def self.call(text)
        letters = text.scan(/\p{L}/).join
        single_case = letters.length > 1 && (letters == letters.downcase || letters == letters.upcase)
        single_case ? Result.issue("name_casing", value: text) : Result.ok(text)
      end
    end
  end
end
