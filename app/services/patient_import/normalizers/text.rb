module PatientImport
  module Normalizers
    module Text
      def self.clean(raw, config: Config.current)
        return if raw.nil?

        text = raw.to_s.unicode_normalize(:nfc).gsub(/[[:space:]]+/, " ").strip
        return if text.empty? || config.placeholder?(text)

        text
      end
    end
  end
end
