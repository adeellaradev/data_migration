class DataMigrationsController < ApplicationController
  def index
    @upload = UploadForm.new
    load_history
  end

  def create
    @upload = UploadForm.new(upload_params)

    if @upload.valid?
      data_migration = PatientImport::Start.call(file: @upload.file, source_name: @upload.source_name, uploaded_by: Current.user)
      redirect_to data_migration, notice: "Migration ##{data_migration.id} started."
    else
      load_history
      render :index, status: :unprocessable_entity
    end
  end

  def show
    @data_migration = DataMigration.includes(:uploaded_by).find(params[:id])
    @outcome_filter = params[:outcome].presence_in(DataMigrationRow::OUTCOMES)
    @issue_filter = params[:issue].presence
    @rows = paginate(filtered_rows)
  end

  private
    def upload_params
      params.fetch(:upload_form, {}).permit(:file, :source_name)
    end

    def load_history
      @data_migrations = paginate(DataMigration.includes(:uploaded_by).recent_first)
    end

    def filtered_rows
      rows = @data_migration.rows
      rows = rows.with_outcome(@outcome_filter) if @outcome_filter
      rows = rows.with_issue_code(@issue_filter) if @issue_filter
      rows
    end
end
