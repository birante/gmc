class RemovePricePerProductFromPlans < ActiveRecord::Migration[8.0]
  def up
    change_column_default :plans, :price, 0
    execute "UPDATE plans SET price = 0 WHERE price IS NULL"
    change_column_null :plans, :price, false
    remove_column :plans, :price_per_product
  end

  def down
    add_column :plans, :price_per_product, :decimal, precision: 10, scale: 2
    change_column_null :plans, :price, true
    change_column_default :plans, :price, nil
  end
end
