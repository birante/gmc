class RemoveDefaultFromStockQuantityInItemVariants < ActiveRecord::Migration[8.0]
  def change
    change_column_default :item_variants, :stock_quantity, from: 0, to: nil
  end
end
