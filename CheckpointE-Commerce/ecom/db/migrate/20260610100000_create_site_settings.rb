class CreateSiteSettings < ActiveRecord::Migration[8.0]
  def change
    create_table :site_settings do |t|
      t.string :key, null: false
      t.string :label
      t.string :description
      t.string :kind, null: false, default: "text"
      t.text :value_fr
      t.text :value_en
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :site_settings, :key, unique: true
  end
end
