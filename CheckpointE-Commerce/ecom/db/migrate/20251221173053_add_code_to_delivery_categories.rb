class AddCodeToDeliveryCategories < ActiveRecord::Migration[8.0]
  def up
    add_column :delivery_categories, :code, :string, null: true
    add_index :delivery_categories, :code, unique: true

    # Backfill: Ajouter les codes pour les catégories existantes
    execute <<-SQL
      UPDATE delivery_categories SET code = 'light' WHERE name = 'Léger';
      UPDATE delivery_categories SET code = 'medium' WHERE name = 'Moyen';
      UPDATE delivery_categories SET code = 'large' WHERE name = 'Grand';
    SQL

    # Générer des codes pour les autres catégories s'il y en a (basé sur le slug du nom)
    DeliveryCategory.where(code: nil).find_each do |category|
      # Générer un code à partir du nom : minuscules, remplacer les espaces/caractères spéciaux par underscores
      code = category.name.downcase
                     .gsub(/[^a-z0-9]+/, '_')
                     .gsub(/^_+|_+$/, '')
                     .presence || "category_#{category.id}"

      # S'assurer que le code est unique
      base_code = code
      counter = 1
      while DeliveryCategory.exists?(code: code)
        code = "#{base_code}_#{counter}"
        counter += 1
      end

      category.update_column(:code, code)
    end

    # S'assurer qu'il n'y a pas de codes NULL avant de rendre le champ obligatoire
    if DeliveryCategory.where(code: nil).exists?
      raise "Des catégories sans code existent. Veuillez les corriger manuellement avant d'exécuter cette migration."
    end

    # Maintenant on peut rendre le champ obligatoire
    change_column_null :delivery_categories, :code, false
  end

  def down
    remove_index :delivery_categories, :code
    remove_column :delivery_categories, :code
  end
end
