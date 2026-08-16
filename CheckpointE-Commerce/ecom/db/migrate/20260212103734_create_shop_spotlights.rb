class CreateShopSpotlights < ActiveRecord::Migration[8.0]
  def change
    create_table :shop_spotlights do |t|
      t.references :home_page_section, null: false, foreign_key: true
      t.references :shop, null: false, foreign_key: true
      t.text :slogan
      t.integer :position, default: 1
      t.string :promo_title
      t.string :promo_subtitle
      t.string :item_ids, comment: "IDs des produits à afficher, séparés par virgules"

      t.timestamps
    end

    add_index :shop_spotlights, [ :home_page_section_id, :position ], name: "index_shop_spotlights_on_section_and_position"
  end
end
