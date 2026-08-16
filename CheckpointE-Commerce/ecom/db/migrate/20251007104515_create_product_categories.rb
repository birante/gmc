class CreateProductCategories < ActiveRecord::Migration[8.0]
  def change
    create_table :product_categories do |t|
      t.string :name
      t.string :slug
      t.text :description
      t.boolean :is_active, default: false

      t.timestamps
    end
    add_index :product_categories, :slug, unique: true
  end
end
