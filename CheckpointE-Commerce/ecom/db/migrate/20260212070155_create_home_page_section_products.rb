class CreateHomePageSectionProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :home_page_section_products do |t|
      t.references :home_page_section, null: false, foreign_key: true
      t.references :item, null: false, foreign_key: true
      t.integer :position, default: 1, null: false
      t.boolean :is_active, default: true, null: false

      t.timestamps
    end

    add_index :home_page_section_products, :position
    add_index :home_page_section_products, :is_active
    add_index :home_page_section_products, [ :home_page_section_id, :item_id ],
              unique: true,
              name: "index_hp_section_products_on_section_and_item"
  end
end
