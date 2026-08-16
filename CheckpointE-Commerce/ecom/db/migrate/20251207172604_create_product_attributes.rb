class CreateProductAttributes < ActiveRecord::Migration[8.0]
  def change
    create_table :product_attributes do |t|
      t.string :name, null: false
      t.text :description
      t.boolean :is_active, default: true, null: false

      t.timestamps
    end

    add_index :product_attributes, :name, unique: true
  end
end
