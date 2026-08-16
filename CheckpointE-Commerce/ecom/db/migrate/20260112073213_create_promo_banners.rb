class CreatePromoBanners < ActiveRecord::Migration[8.0]
  def change
    create_table :promo_banners do |t|
      t.references :home_page_section, null: false, foreign_key: true
      t.string :title
      t.string :cta_text
      t.string :cta_link
      t.integer :position

      t.timestamps
    end
  end
end
