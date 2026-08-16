# frozen_string_literal: true

class CreateHomePageSectionGroups < ActiveRecord::Migration[8.0]
  def change
    create_table :home_page_section_groups do |t|
      t.references :home_page_section, null: false, foreign_key: true
      t.string :title, null: false
      t.string :link, null: false
      t.integer :position, null: false, default: 1
      t.boolean :is_active, null: false, default: true

      t.timestamps
    end

    add_index :home_page_section_groups, :position
    add_index :home_page_section_groups, :is_active
  end
end
