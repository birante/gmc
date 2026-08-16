class AddPositionToProductSubCategories < ActiveRecord::Migration[8.0]
  def change
    add_column :product_sub_categories, :position, :integer
  end
end
