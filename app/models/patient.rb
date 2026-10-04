class Patient < ApplicationRecord
  SEXES = %w[male female non_binary unknown].freeze

  MIGRATABLE_ATTRIBUTES = %w[
    health_number health_number_province
    first_name middle_name last_name date_of_birth sex
    email phone
    address_line1 address_line2 city address_province postal_code
  ].freeze

  attribute :date_of_birth, :date

  encrypts :health_number, deterministic: true
  encrypts :first_name, :middle_name, :last_name, :date_of_birth,
    :email, :phone, :address_line1, :address_line2, :city, :postal_code

  belongs_to :created_by_migration, class_name: "DataMigration", optional: true
  belongs_to :last_changed_by_migration, class_name: "DataMigration", optional: true

  validates :health_number, presence: true
  validates :health_number_province, inclusion: { in: Province::CODES }
  validates :health_number, uniqueness: { scope: :health_number_province }
  validates :address_province, inclusion: { in: Province::CODES }, allow_nil: true
  validates :sex, inclusion: { in: SEXES }

  def full_name
    [ first_name, middle_name, last_name ].compact_blank.join(" ")
  end
end
