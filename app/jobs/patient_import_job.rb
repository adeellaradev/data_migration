class PatientImportJob < ApplicationJob
  queue_as :default

  def perform(data_migration_id)
    data_migration = DataMigration.find_by(id: data_migration_id)
    return unless data_migration

    runner = PatientImport::Runner.new(data_migration)
    if data_migration.pending?
      runner.call
    elsif data_migration.running?
      runner.abandon
    end
  end
end
