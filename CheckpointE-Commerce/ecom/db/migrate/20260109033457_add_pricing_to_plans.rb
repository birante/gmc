class AddPricingToPlans < ActiveRecord::Migration[8.0]
  def change
    add_column :plans, :price, :decimal, precision: 10, scale: 2
    add_column :plans, :billing_period_months, :integer
    add_column :plans, :price_per_product, :decimal, precision: 10, scale: 2
  end
end
