# frozen_string_literal: true

class AddTrackableReferencesToAhoyEvents < ActiveRecord::Migration[8.0]
  def change
    # Ajouter les références pour tracker les boutiques et produits
    add_column :ahoy_events, :shop_id, :bigint
    add_column :ahoy_events, :item_id, :bigint

    # Ajouter les index pour les requêtes
    add_index :ahoy_events, :shop_id
    add_index :ahoy_events, :item_id
    add_index :ahoy_events, [ :name, :shop_id ]
    add_index :ahoy_events, [ :name, :item_id ]
    add_index :ahoy_events, [ :name, :time, :shop_id ]
    add_index :ahoy_events, [ :name, :time, :item_id ]

    # Ajouter les clés étrangères (optionnel, mais recommandé)
    add_foreign_key :ahoy_events, :shops, on_delete: :nullify
    add_foreign_key :ahoy_events, :items, on_delete: :nullify
  end
end
