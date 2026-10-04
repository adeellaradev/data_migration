class CreatePatients < ActiveRecord::Migration[8.1]
  PROVINCES = %w[AB BC MB NB NL NS NT NU ON PE QC SK YT].freeze

  def change
    create_table :patients do |t|
      t.text :health_number, null: false
      t.string :health_number_province, limit: 2, null: false

      t.text :first_name
      t.text :middle_name
      t.text :last_name
      t.text :date_of_birth
      t.text :email
      t.text :phone
      t.text :address_line1
      t.text :address_line2
      t.text :city
      t.text :postal_code

      t.string :sex, null: false, default: "unknown"
      t.string :address_province, limit: 2

      t.references :created_by_migration, foreign_key: { to_table: :data_migrations }
      t.references :last_changed_by_migration, foreign_key: { to_table: :data_migrations }

      t.timestamps
    end

    add_index :patients, [ :health_number_province, :health_number ], unique: true,
      name: "index_patients_on_health_number_identity"

    provinces = PROVINCES.map { |p| "'#{p}'" }.join(", ")
    add_check_constraint :patients, "health_number_province IN (#{provinces})",
      name: "patients_health_number_province_check"
    add_check_constraint :patients, "address_province IS NULL OR address_province IN (#{provinces})",
      name: "patients_address_province_check"
    add_check_constraint :patients, "sex IN ('male', 'female', 'non_binary', 'unknown')",
      name: "patients_sex_check"
  end
end
