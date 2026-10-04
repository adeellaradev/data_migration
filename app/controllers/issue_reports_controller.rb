class IssueReportsController < ApplicationController
  def show
    data_migration = DataMigration.find(params[:data_migration_id])
    report = PatientImport::IssueReport.new(data_migration)

    send_data report.to_csv, filename: report.filename, type: "text/csv", disposition: "attachment"
  end
end
