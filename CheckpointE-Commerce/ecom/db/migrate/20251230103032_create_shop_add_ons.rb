class CreateShopAddOns < ActiveRecord::Migration[8.0]
  def change
    create_table :shop_add_ons do |t|
      t.references :shop, null: false, foreign_key: true
      t.references :add_on, null: false, foreign_key: true
      t.integer :quantity
      t.datetime :starts_at
      t.datetime :ends_at

      t.timestamps
    end
  end
end
