class AddOriginCountryToItems < ActiveRecord::Migration[8.0]
  def change
    add_column :items, :origin_country, :string
    add_index :items, :origin_country

    # Migrer les données existantes : produits dans la catégorie "Made in Sénégal"
    reversible do |dir|
      dir.up do
        Item.reset_column_information
        Item.joins(product_sub_category: :product_category)
            .where(product_categories: { name: "Made in Sénégal / Made in Africa" })
            .update_all(origin_country: 'SN')
      end
    end
  end
end
