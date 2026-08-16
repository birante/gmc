class MigratePriceToVariants < ActiveRecord::Migration[8.0]
  def up
    # Pour chaque item existant, créer une variante par défaut avec le prix et stock actuels
    Item.find_each do |item|
      # Ignorer les validations temporairement pour la migration
      variant = ItemVariant.new(
        item: item,
        price: item.price&.positive? ? item.price : 0.01,
        stock_quantity: item.stock_quantity || 0,
        sku: "#{item.id}-DEFAULT"
      )
      variant.save(validate: false)
    end

    # Supprimer les colonnes price et stock_quantity de la table items
    remove_column :items, :price, :decimal
    remove_column :items, :stock_quantity, :integer
  end

  def down
    # Restaurer les colonnes
    add_column :items, :price, :decimal, precision: 10, scale: 2
    add_column :items, :stock_quantity, :integer, default: 0

    # Récupérer les données de la première variante de chaque item
    Item.find_each do |item|
      first_variant = item.variants.first
      if first_variant
        item.update_columns(
          price: first_variant.price,
          stock_quantity: first_variant.stock_quantity
        )
      end
    end

    # Supprimer toutes les variantes
    ItemVariant.delete_all
  end
end
