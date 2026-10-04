Rails.application.config.to_prepare do
  PatientImport::Config.reload!
end
