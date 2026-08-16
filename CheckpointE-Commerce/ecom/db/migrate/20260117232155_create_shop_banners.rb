class CreateShopBanners < ActiveRecord::Migration[8.0]
  def change
    create_table :shop_banners do |t|
      t.references :shop, null: false, foreign_key: true
      t.integer :position, default: 0
      t.string :title
      t.string :cta_text
      t.string :cta_link

      t.timestamps
    end

    add_index :shop_banners, [ :shop_id, :position ]
  end
end
