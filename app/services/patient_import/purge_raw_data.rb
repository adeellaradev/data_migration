module PatientImport
  class PurgeRawData
    def self.call(config: Config.current, now: Time.current)
      DataMigrationRow
        .where(raw_data_purged_at: nil)
        .where(created_at: ...(now - config.raw_data_retention_days.days))
        .update_all(raw_data: nil, changed_fields: nil, raw_data_purged_at: now, updated_at: now)
    end
  end
end
