class DataMigrationRow < ApplicationRecord
  OUTCOMES = %w[created updated unchanged rejected duplicate].freeze

  serialize :raw_data, coder: JSON
  serialize :changed_fields, coder: JSON
  encrypts :raw_data, :changed_fields

  belongs_to :data_migration
  belongs_to :patient, optional: true

  validates :row_number, presence: true
  validates :outcome, inclusion: { in: OUTCOMES }

  scope :with_outcome, ->(outcome) { where(outcome: outcome) }
  scope :with_issue_code, ->(code) { where("issues @> ?", [ { code: code } ].to_json) }
  scope :with_issues, -> { where("jsonb_array_length(issues) > 0") }

  def errors_list
    issues.select { |i| i["severity"] == "error" }
  end

  def warnings
    issues.select { |i| i["severity"] == "warning" }
  end
end
