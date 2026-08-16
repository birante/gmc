class CreateAddresses < ActiveRecord::Migration[8.0]
  def change
    create_table :addresses do |t|
      t.references :user, null: false, foreign_key: true
      t.text :street_address, null: false
      t.string :city
      t.string :postal_code
      t.string :country, default: "SN"
      t.boolean :is_default, default: false
      t.decimal :latitude, precision: 10, scale: 7
      t.decimal :longitude, precision: 10, scale: 7

      t.timestamps
    end

    add_index :addresses, [ :user_id, :is_default ]
  end
end
