class RemoveShopIdFromEmployees < ActiveRecord::Migration[8.0]
  def change
    remove_reference :employees, :shop, null: false, foreign_key: true
  end
end
