class CreateEmployees < ActiveRecord::Migration[8.0]
  def change
    create_table :employees do |t|
      t.references :vendor, null: false, foreign_key: true
      t.references :shop, null: false, foreign_key: true
      t.string :email, null: false
      t.string :password_digest, null: false
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :country_code, default: "221"
      t.string :phone_number
      t.string :role, null: false, default: "cashier"
      t.boolean :status, default: true, null: false

      t.timestamps
    end

    add_index :employees, :email, unique: true
    add_index :employees, [ :vendor_id, :shop_id ]
    add_index :employees, :status
  end
end
