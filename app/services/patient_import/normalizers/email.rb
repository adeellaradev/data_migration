module PatientImport
  module Normalizers
    module Email
      def self.call(text)
        email = text.delete_prefix("mailto:").sub(/[\s;,.]+\z/, "").downcase
        valid = email.match?(URI::MailTo::EMAIL_REGEXP) && email.split("@").last.include?(".")
        valid ? Result.ok(email) : Result.issue("invalid_email")
      end
    end
  end
end
