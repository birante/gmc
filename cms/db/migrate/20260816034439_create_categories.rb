class CreateCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :categories do |t|
      t.string :name
      t.string :slug
      t.text :description
      t.integer :parent_id
      t.integer :display_order
      t.boolean :active

      t.timestamps
    end
    add_index :categories, :slug, unique: true
    add_index :categories, :parent_id
  end
end
