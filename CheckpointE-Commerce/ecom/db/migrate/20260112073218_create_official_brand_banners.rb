class CreateOfficialBrandBanners < ActiveRecord::Migration[8.0]
  def change
    create_table :official_brand_banners do |t|
      t.references :home_page_section, null: false, foreign_key: true
      t.string :name
      t.string :link
      t.integer :position

      t.timestamps
    end
  end
end
