class AddItemVariantToCartItems < ActiveRecord::Migration[8.0]
  def change
    add_reference :cart_items, :item_variant, null: true, foreign_key: true
  end
end
