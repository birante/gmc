# frozen_string_literal: true

class CreateHomePageSectionGroupItems < ActiveRecord::Migration[8.0]
  def change
    create_table :home_page_section_group_items do |t|
      t.references :home_page_section_group, null: false, foreign_key: true
      t.string :title, null: false
      t.string :link, null: false
      t.integer :position, null: false, default: 1
      t.boolean :is_active, null: false, default: true

      t.timestamps
    end

    add_index :home_page_section_group_items, :position
    add_index :home_page_section_group_items, :is_active
  end
end
