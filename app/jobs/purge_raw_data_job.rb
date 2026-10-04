class PurgeRawDataJob < ApplicationJob
  queue_as :default

  def perform
    purged = PatientImport::PurgeRawData.call
    Rails.logger.info("PurgeRawDataJob wiped raw data from #{purged} migration rows")
  end
end
