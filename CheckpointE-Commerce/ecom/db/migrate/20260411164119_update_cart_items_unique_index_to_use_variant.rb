class UpdateCartItemsUniqueIndexToUseVariant < ActiveRecord::Migration[8.0]
  def up
    remove_index :cart_items, name: :index_cart_items_on_cart_id_and_item_id, if_exists: true

    unless index_name_exists?(:cart_items, :index_cart_items_on_cart_id_and_item_variant_id)
      add_index :cart_items, [ :cart_id, :item_variant_id ], unique: true, name: :index_cart_items_on_cart_id_and_item_variant_id
    end
  end

  def down
    remove_index :cart_items, name: :index_cart_items_on_cart_id_and_item_variant_id, if_exists: true

    unless index_name_exists?(:cart_items, :index_cart_items_on_cart_id_and_item_id)
      add_index :cart_items, [ :cart_id, :item_id ], unique: true, name: :index_cart_items_on_cart_id_and_item_id
    end
  end
end
