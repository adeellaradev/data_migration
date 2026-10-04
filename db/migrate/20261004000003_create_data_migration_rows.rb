class CreateDataMigrationRows < ActiveRecord::Migration[8.1]
  def change
    create_table :data_migration_rows do |t|
      t.references :data_migration, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.references :patient, foreign_key: true
      t.integer :row_number, null: false
      t.string :outcome, null: false

      t.text :raw_data
      t.text :changed_fields
      t.datetime :raw_data_purged_at

      t.jsonb :issues, null: false, default: []

      t.timestamps
    end

    add_index :data_migration_rows, [ :data_migration_id, :row_number ], unique: true
    add_index :data_migration_rows, [ :data_migration_id, :outcome ]
    add_index :data_migration_rows, :issues, using: :gin
    add_check_constraint :data_migration_rows,
      "outcome IN ('created', 'updated', 'unchanged', 'rejected', 'duplicate')",
      name: "data_migration_rows_outcome_check"
  end
end
