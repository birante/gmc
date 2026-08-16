class CreateEmployeeShops < ActiveRecord::Migration[8.0]
  def change
    create_table :employee_shops do |t|
      t.references :employee, null: false, foreign_key: true
      t.references :shop, null: false, foreign_key: true
      t.boolean :is_primary, default: false, null: false

      t.timestamps
    end

    # Index pour éviter les doublons
    add_index :employee_shops, [ :employee_id, :shop_id ], unique: true
  end
end
