# frozen_string_literal: true

class CreateShopPageHeaderSlides < ActiveRecord::Migration[8.0]
  def change
    create_table :shop_page_header_slides do |t|
      t.references :shop, null: false, foreign_key: true
      t.string :link
      t.string :button_text
      t.integer :position, default: 1, null: false

      t.timestamps
    end

    add_index :shop_page_header_slides, [ :shop_id, :position ]
  end
end
