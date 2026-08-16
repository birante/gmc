# frozen_string_literal: true

class AddCommissionRateToShops < ActiveRecord::Migration[8.0]
  def change
    add_column :shops, :commission_rate, :decimal, precision: 5, scale: 4, null: false, default: 0.1
  end
end
