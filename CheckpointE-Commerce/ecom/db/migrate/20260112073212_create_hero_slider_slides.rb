class CreateHeroSliderSlides < ActiveRecord::Migration[8.0]
  def change
    create_table :hero_slider_slides do |t|
      t.references :home_page_section, null: false, foreign_key: true
      t.string :badge_text
      t.string :badge_bg_color
      t.string :badge_text_color
      t.string :title
      t.string :cta_text
      t.string :cta_link
      t.string :gradient
      t.integer :position

      t.timestamps
    end
  end
end
