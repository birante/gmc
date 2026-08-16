class CreateVendors < ActiveRecord::Migration[8.0]
  def change
    create_table :vendors do |t|
      t.string :first_name
      t.string :last_name
      t.string :phone_number
      t.string :country_code
      t.string :email
      t.string :password_digest
      t.string :password_confirmation
      t.boolean :status

      t.timestamps
    end
  end
end
