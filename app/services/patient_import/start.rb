module PatientImport
  class Start
    def self.call(file:, source_name:, uploaded_by:, filename: file.original_filename)
      content = file.read

      data_migration = DataMigration.create!(
        source_name: source_name,
        filename: filename,
        uploaded_by: uploaded_by,
        file_sha256: Digest::SHA256.hexdigest(content),
        source_file: { io: StringIO.new(content), filename: filename, content_type: "text/csv" }
      )

      PatientImportJob.perform_later(data_migration.id)
      data_migration
    end
  end
end
