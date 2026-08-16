# frozen_string_literal: true

class AddCounterCachesToShopsAndItemsAndUsers < ActiveRecord::Migration[8.0]
  def change
    # Counter caches pour Shop
    add_column :shops, :items_count, :integer, default: 0, null: false
    add_column :shops, :available_items_count, :integer, default: 0, null: false
    add_index :shops, :items_count
    add_index :shops, :available_items_count

    # Counter cache pour Item
    add_column :items, :variants_count, :integer, default: 0, null: false
    add_index :items, :variants_count

    # Counter cache pour User
    add_column :users, :orders_count, :integer, default: 0, null: false
    add_index :users, :orders_count

    # Migrer les données existantes
    reversible do |dir|
      dir.up do
        # Initialiser items_count pour les shops
        execute <<-SQL
          UPDATE shops
          SET items_count = (
            SELECT COUNT(*)
            FROM items
            WHERE items.shop_id = shops.id
          )
        SQL

        # Initialiser available_items_count pour les shops
        execute <<-SQL
          UPDATE shops
          SET available_items_count = (
            SELECT COUNT(*)
            FROM items
            WHERE items.shop_id = shops.id
            AND items.validation_status = 'approved'
            AND items.is_active = true
          )
        SQL

        # Initialiser variants_count pour les items
        execute <<-SQL
          UPDATE items
          SET variants_count = (
            SELECT COUNT(*)
            FROM item_variants
            WHERE item_variants.item_id = items.id
          )
        SQL

        # Initialiser orders_count pour les users
        execute <<-SQL
          UPDATE users
          SET orders_count = (
            SELECT COUNT(*)
            FROM orders
            WHERE orders.user_id = users.id
          )
        SQL
      end
    end
  end
end
