class MakeProductSubCategoryOptionalInItems < ActiveRecord::Migration[8.0]
  def change
    change_column_null :items, :product_sub_category_id, true
  end
end
