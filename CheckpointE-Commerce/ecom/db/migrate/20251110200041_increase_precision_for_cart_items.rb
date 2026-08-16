class IncreasePrecisionForCartItems < ActiveRecord::Migration[8.0]
  def change
    change_column :cart_items, :unit_price, :decimal, precision: 12, scale: 2
    change_column :cart_items, :total_price, :decimal, precision: 12, scale: 2
  end
end
