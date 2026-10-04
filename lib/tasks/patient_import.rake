namespace :patient_import do
  desc "Wipe raw row data older than the retention period in config/data_migration.yml"
  task purge_raw_data: :environment do
    puts "Wiped raw data from #{PatientImport::PurgeRawData.call} migration rows."
  end
end
