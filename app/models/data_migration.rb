class DataMigration < ApplicationRecord
  STATUSES = %w[pending running completed failed].freeze

  belongs_to :uploaded_by, class_name: "User", inverse_of: :data_migrations
  has_one_attached :source_file
  has_many :rows, -> { order(:row_number) }, class_name: "DataMigrationRow", dependent: :delete_all

  validates :source_name, :filename, :file_sha256, presence: true
  validates :status, inclusion: { in: STATUSES }

  scope :recent_first, -> { order(created_at: :desc) }

  STATUSES.each do |s|
    define_method(:"#{s}?") { status == s }
  end

  def finished?
    completed? || failed?
  end

  def duration
    return unless started_at && finished_at

    finished_at - started_at
  end

  def rows_per_second
    return unless duration&.positive?

    (total_rows / duration).round(1)
  end

  def previous_identical_migrations
    DataMigration.where(file_sha256: file_sha256).where.not(id: id).where(created_at: ...created_at).recent_first
  end
end
