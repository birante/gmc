class AddPositionToProductCategories < ActiveRecord::Migration[8.0]
  def change
    add_column :product_categories, :position, :integer
  end
end
