class User < ApplicationRecord
  PASSWORD_MIN_LENGTH = 12

  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :data_migrations, foreign_key: :uploaded_by_id, inverse_of: :uploaded_by, dependent: :restrict_with_error

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true
  validates :password, length: { minimum: PASSWORD_MIN_LENGTH }, allow_nil: true
end
