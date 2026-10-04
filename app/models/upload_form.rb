class UploadForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  MAX_FILE_SIZE = 10.megabytes
  DEFAULT_SOURCE_NAME = "Health For You Clinic"

  attribute :file
  attribute :source_name, :string, default: DEFAULT_SOURCE_NAME

  validates :source_name, presence: true, length: { maximum: 200 }
  validate :file_must_be_a_csv

  private
    def file_must_be_a_csv
      if file.blank? || !file.respond_to?(:original_filename)
        errors.add(:file, "must be selected")
      elsif !File.extname(file.original_filename.to_s).casecmp?(".csv")
        errors.add(:file, "must be a .csv file")
      elsif file.size.zero?
        errors.add(:file, "is empty")
      elsif file.size > MAX_FILE_SIZE
        errors.add(:file, "must be smaller than #{MAX_FILE_SIZE / 1.megabyte} MB")
      end
    end
end
