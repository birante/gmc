class CreateDeliveryCategories < ActiveRecord::Migration[8.0]
  def change
    create_table :delivery_categories do |t|
      t.string :name, null: false
      t.text :description
      t.integer :display_order, null: false, default: 0

      t.timestamps
    end

    add_index :delivery_categories, :name, unique: true
    add_index :delivery_categories, :display_order
  end
end
