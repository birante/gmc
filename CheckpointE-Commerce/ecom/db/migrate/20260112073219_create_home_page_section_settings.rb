class CreateHomePageSectionSettings < ActiveRecord::Migration[8.0]
  def change
    create_table :home_page_section_settings do |t|
      t.references :home_page_section, null: false, foreign_key: true
      t.string :key
      t.text :value

      t.timestamps
    end
  end
end
