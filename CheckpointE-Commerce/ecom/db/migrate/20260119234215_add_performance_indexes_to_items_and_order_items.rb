# frozen_string_literal: true

class AddPerformanceIndexesToItemsAndOrderItems < ActiveRecord::Migration[8.0]
  def change
    # Indexes composés pour Item - requêtes fréquentes
    add_index :items, [ :shop_id, :validation_status, :is_on_sale ],
              name: 'index_items_on_shop_status_sale'
    add_index :items, [ :product_sub_category_id, :validation_status ],
              name: 'index_items_on_subcategory_status'
    add_index :items, [ :validation_status, :created_at ],
              name: 'index_items_on_status_created'
    add_index :items, [ :validation_status, :is_active ],
              name: 'index_items_on_status_active'

    # Index partiel pour les items disponibles à la vente (très fréquent)
    add_index :items, :validation_status,
              where: "validation_status = 'approved' AND is_active = true",
              name: 'index_items_on_available_for_sale'

    # Index pour l'origine des produits
    unless index_exists?(:items, :origin_country)
      add_index :items, :origin_country, where: "origin_country = 'SN'"
    end

    # Indexes composés pour OrderItem - requêtes fréquentes
    add_index :order_items, [ :shop_id, :delivery_status, :created_at ],
              name: 'index_order_items_on_shop_status_created'
    add_index :order_items, [ :order_id, :shop_id ],
              name: 'index_order_items_on_order_shop'
    add_index :order_items, [ :item_variant_id, :delivery_status ],
              name: 'index_order_items_on_variant_status'

    # Indexes pour Shop
    add_index :shops, [ :status, :shop_type, :created_at ],
              name: 'index_shops_on_status_type_created'

    # Index partiel pour vendor_id avec status active (si l'index vendor_id n'existe pas déjà)
    unless index_exists?(:shops, :vendor_id, where: "status = 'active'")
      add_index :shops, :vendor_id, where: "status = 'active'"
    end

    # Indexes pour Order
    add_index :orders, [ :user_id, :status, :created_at ],
              name: 'index_orders_on_user_status_created'
    add_index :orders, [ :status, :created_at ],
              name: 'index_orders_on_status_created'

    # Indexes pour ItemVariant
    add_index :item_variants, [ :item_id, :is_default ],
              name: 'index_item_variants_on_item_default'
    add_index :item_variants, [ :item_id, :stock_quantity ],
              name: 'index_item_variants_on_item_stock'
  end
end
