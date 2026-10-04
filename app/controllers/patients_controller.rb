class PatientsController < ApplicationController
  def index
    @health_number = params[:health_number].to_s.strip
    @province = params[:province].presence_in(Province::CODES)
    @patients = paginate(search_scope)
  end

  def show
    @patient = Patient.includes(:created_by_migration, :last_changed_by_migration).find(params[:id])
    @history = DataMigrationRow.where(patient: @patient).includes(:data_migration).order(created_at: :desc)
  end

  private
    def search_scope
      scope = Patient.order(:id)
      return scope if @health_number.blank?

      health_number = PatientImport::Normalizers::HealthNumber.call(@health_number).value
      scope = scope.where(health_number: health_number)
      @province ? scope.where(health_number_province: @province) : scope
    end
end
