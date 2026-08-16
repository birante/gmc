class CreateSecondaryBanners < ActiveRecord::Migration[8.0]
  def change
    create_table :secondary_banners do |t|
      t.references :home_page_section, null: false, foreign_key: true
      t.string :title
      t.string :link
      t.string :gradient_from
      t.string :gradient_to
      t.string :position_type
      t.integer :position_order

      t.timestamps
    end
  end
end
