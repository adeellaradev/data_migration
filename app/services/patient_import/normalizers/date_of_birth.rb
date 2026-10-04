module PatientImport
  module Normalizers
    module DateOfBirth
      ISO_DATE = /\A(\d{4})-(\d{2})-(\d{2})\z/
      EARLIEST_YEAR = 1900

      def self.call(text, today: Date.current)
        match = ISO_DATE.match(text)
        return Result.issue("invalid_date_of_birth") unless match

        year, month, day = match.captures.map(&:to_i)
        return Result.issue("invalid_date_of_birth") unless Date.valid_date?(year, month, day)

        date = Date.new(year, month, day)
        return Result.issue("future_date_of_birth") if date > today
        return Result.issue("implausible_date_of_birth") if year < EARLIEST_YEAR

        Result.ok(date)
      end
    end
  end
end
