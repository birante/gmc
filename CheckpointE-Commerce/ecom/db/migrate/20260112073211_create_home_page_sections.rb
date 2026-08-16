class CreateHomePageSections < ActiveRecord::Migration[8.0]
  def change
    create_table :home_page_sections do |t|
      t.string :section_type
      t.string :title
      t.text :description
      t.boolean :is_active
      t.integer :position

      t.timestamps
    end
  end
end
