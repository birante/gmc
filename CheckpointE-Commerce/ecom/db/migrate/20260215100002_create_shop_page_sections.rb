# frozen_string_literal: true

class CreateShopPageSections < ActiveRecord::Migration[8.0]
  def change
    create_table :shop_page_sections do |t|
      t.references :shop, null: false, foreign_key: true
      t.string :section_type, null: false
      t.string :title
      t.text :description
      t.integer :position, default: 0, null: false
      t.boolean :is_active, default: true, null: false

      t.timestamps
    end

    add_index :shop_page_sections, [ :shop_id, :position ]
    add_index :shop_page_sections, [ :shop_id, :section_type ]
  end
end
