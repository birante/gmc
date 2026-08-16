# frozen_string_literal: true

class CreateShopPageSectionCategories < ActiveRecord::Migration[8.0]
  def change
    create_table :shop_page_section_categories do |t|
      t.references :shop_page_section, null: false, foreign_key: true
      t.references :product_sub_category, null: false, foreign_key: true
      t.integer :position, default: 1, null: false

      t.timestamps
    end

    add_index :shop_page_section_categories, :position
    add_index :shop_page_section_categories, [ :shop_page_section_id, :product_sub_category_id ],
              unique: true,
              name: "index_shop_page_section_cats_on_section_and_subcat"
  end
end
