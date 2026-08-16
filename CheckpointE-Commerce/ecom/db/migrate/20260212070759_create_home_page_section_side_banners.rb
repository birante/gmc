class CreateHomePageSectionSideBanners < ActiveRecord::Migration[8.0]
  def change
    create_table :home_page_section_side_banners do |t|
      t.references :home_page_section, null: false, foreign_key: true
      t.string :title
      t.string :subtitle
      t.text :description
      t.string :cta_text
      t.string :cta_link
      t.string :bg_color, default: "#f3de6d"
      t.string :text_color, default: "#ffffff"
      t.integer :position, default: 1, null: false
      t.boolean :is_active, default: true, null: false

      t.timestamps
    end

    add_index :home_page_section_side_banners, :position
    add_index :home_page_section_side_banners, :is_active
  end
end
