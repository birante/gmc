class CreateItemVariants < ActiveRecord::Migration[8.0]
  def change
    create_table :item_variants do |t|
      t.references :item, null: false, foreign_key: true
      t.string :size
      t.string :color
      t.string :sku, index: { unique: true }
      t.decimal :price, precision: 10, scale: 2, null: false
      t.integer :stock_quantity, default: 0, null: false

      t.timestamps
    end
  end
end
