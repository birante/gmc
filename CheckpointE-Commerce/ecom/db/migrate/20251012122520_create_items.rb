class CreateItems < ActiveRecord::Migration[8.0]
  def change
    create_table :items do |t|
      t.references :shop, null: false, foreign_key: true
      t.references :product_sub_category, null: false, foreign_key: true
      t.references :currency, null: false, foreign_key: true
      t.string :name
      t.decimal :price, precision: 8, scale: 2, default: 0.0
      t.integer :stock_quantity, default: 0
      t.string :validation_status, default: "pending"
      t.boolean :is_active, default: false
      t.integer :position
      t.string :slug
      t.text :description

      t.timestamps
    end
  end
end
