class CreateOrderItems < ActiveRecord::Migration[8.0]
  def change
    create_table :order_items do |t|
      t.references :order, null: false, foreign_key: true
      t.references :item, null: false, foreign_key: true
      t.references :shop, null: false, foreign_key: true
      t.decimal :unit_price
      t.integer :quantity
      t.decimal :total_price
      t.string :delivery_status

      t.timestamps
    end
  end
end
