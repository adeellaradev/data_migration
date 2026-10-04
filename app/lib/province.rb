module Province
  NAMES = {
    "AB" => "Alberta",
    "BC" => "British Columbia",
    "MB" => "Manitoba",
    "NB" => "New Brunswick",
    "NL" => "Newfoundland and Labrador",
    "NS" => "Nova Scotia",
    "NT" => "Northwest Territories",
    "NU" => "Nunavut",
    "ON" => "Ontario",
    "PE" => "Prince Edward Island",
    "QC" => "Quebec",
    "SK" => "Saskatchewan",
    "YT" => "Yukon"
  }.freeze

  CODES = NAMES.keys.freeze

  POSTAL_CODE_LETTERS = {
    "AB" => %w[T],
    "BC" => %w[V],
    "MB" => %w[R],
    "NB" => %w[E],
    "NL" => %w[A],
    "NS" => %w[B],
    "NT" => %w[X],
    "NU" => %w[X],
    "ON" => %w[K L M N P],
    "PE" => %w[C],
    "QC" => %w[G H J],
    "SK" => %w[S],
    "YT" => %w[Y]
  }.freeze

  def self.name_for(code)
    NAMES[code]
  end

  def self.postal_code_matches?(code, postal_code)
    POSTAL_CODE_LETTERS.fetch(code, []).include?(postal_code.to_s[0])
  end
end
