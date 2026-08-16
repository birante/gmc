class CreateProductSubCategories < ActiveRecord::Migration[8.0]
  def change
    create_table :product_sub_categories do |t|
      t.string :name
      t.string :slug
      t.text :description
      t.boolean :is_active, default: false
      t.references :product_category, null: false, foreign_key: true

      t.timestamps
    end
    add_index :product_sub_categories, :slug, unique: true
  end
end
