class AddUploadedByToDataMigrations < ActiveRecord::Migration[8.1]
  def change
    add_reference :data_migrations, :uploaded_by, null: false, foreign_key: { to_table: :users }
  end
end
