class PatientImportJob < ApplicationJob
  queue_as :default

  def perform(data_migration_id)
    data_migration = DataMigration.find_by(id: data_migration_id)
    PatientImport::Runner.new(data_migration).call if data_migration&.pending?
  end
end
