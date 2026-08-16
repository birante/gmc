class CreateShopContacts < ActiveRecord::Migration[8.0]
  def change
    create_table :shop_contacts do |t|
      t.references :shop, null: false, foreign_key: true
      t.string :country_code
      t.string :phone_number
      t.boolean :is_whatsapp

      t.timestamps
    end
  end
end
