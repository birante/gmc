# frozen_string_literal: true

class AddTrackingToShopsAndItems < ActiveRecord::Migration[8.0]
  def change
    # Ajouter les compteurs de vues
    add_column :shops, :views_count, :integer, default: 0, null: false
    add_column :items, :views_count, :integer, default: 0, null: false

    # Ajouter les index pour performance
    add_index :shops, :views_count
    add_index :items, :views_count
  end
end
