class CreateDeliveryPrices < ActiveRecord::Migration[8.0]
  def change
    create_table :delivery_prices do |t|
      t.references :delivery_zone, null: false, foreign_key: true
      t.references :delivery_category, null: false, foreign_key: true
      t.decimal :price, precision: 10, scale: 2, null: false, default: 0.0

      t.timestamps
    end

    add_index :delivery_prices, [ :delivery_zone_id, :delivery_category_id ],
              unique: true, name: 'index_delivery_prices_on_zone_and_category'
  end
end
