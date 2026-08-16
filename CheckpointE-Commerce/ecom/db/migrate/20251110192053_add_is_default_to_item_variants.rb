class AddIsDefaultToItemVariants < ActiveRecord::Migration[8.0]
  def change
    add_column :item_variants, :is_default, :boolean, default: false, null: false

    # Marquer les variantes existantes avec SKU *-DEFAULT comme variantes par défaut
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE item_variants
          SET is_default = true
          WHERE sku LIKE '%-DEFAULT'
        SQL
      end
    end
  end
end
