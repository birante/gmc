# frozen_string_literal: true

class ChangeDefaultCommissionRateOnShops < ActiveRecord::Migration[8.0]
  def change
    change_column_default :shops, :commission_rate, from: 0.1, to: 0.0
  end
end
