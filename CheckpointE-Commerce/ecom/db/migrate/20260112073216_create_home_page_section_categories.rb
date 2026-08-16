class CreateHomePageSectionCategories < ActiveRecord::Migration[8.0]
  def change
    create_table :home_page_section_categories do |t|
      t.references :home_page_section, null: false, foreign_key: true
      t.references :product_category, null: false, foreign_key: true
      t.references :product_sub_category, null: false, foreign_key: true
      t.integer :position

      t.timestamps
    end
  end
end
