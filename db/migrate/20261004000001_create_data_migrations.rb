class CreateDataMigrations < ActiveRecord::Migration[8.1]
  def change
    create_table :data_migrations do |t|
      t.string :source_name, null: false
      t.string :filename, null: false
      t.string :file_sha256, null: false
      t.string :status, null: false, default: "pending"
      t.datetime :started_at
      t.datetime :finished_at

      t.integer :total_rows, null: false, default: 0
      t.integer :created_count, null: false, default: 0
      t.integer :updated_count, null: false, default: 0
      t.integer :unchanged_count, null: false, default: 0
      t.integer :rejected_count, null: false, default: 0
      t.integer :duplicate_count, null: false, default: 0
      t.integer :rows_with_warnings_count, null: false, default: 0

      t.jsonb :stats, null: false, default: {}

      t.text :error_message

      t.datetime :source_file_purged_at

      t.timestamps
    end

    add_index :data_migrations, :file_sha256
    add_index :data_migrations, :created_at
    add_check_constraint :data_migrations,
      "status IN ('pending', 'running', 'completed', 'failed')",
      name: "data_migrations_status_check"
  end
end
