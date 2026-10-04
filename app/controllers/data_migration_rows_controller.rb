class DataMigrationRowsController < ApplicationController
  def show
    @data_migration = DataMigration.find(params[:data_migration_id])
    @row = @data_migration.rows.includes(:patient).find(params[:id])
  end
end
