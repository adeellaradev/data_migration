module PatientImport
  module Normalizers
    Result = Data.define(:value, :issue_code) do
      def self.ok(value)
        new(value: value, issue_code: nil)
      end

      def self.issue(code, value: nil)
        new(value: value, issue_code: code)
      end
    end
  end
end
