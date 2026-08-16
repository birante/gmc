# frozen_string_literal: true

class CreateShopPageHeaders < ActiveRecord::Migration[8.0]
  def change
    create_table :shop_page_headers do |t|
      t.references :shop, null: false, foreign_key: true, index: { unique: true }
      t.string :link
      t.string :button_text

      t.timestamps
    end
  end
end
