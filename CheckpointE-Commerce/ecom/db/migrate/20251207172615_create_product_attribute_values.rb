class CreateProductAttributeValues < ActiveRecord::Migration[8.0]
  def change
    create_table :product_attribute_values do |t|
      t.references :product_attribute, null: false, foreign_key: true
      t.string :value, null: false
      t.boolean :is_active, default: true, null: false

      t.timestamps
    end

    add_index :product_attribute_values, [ :product_attribute_id, :value ], unique: true, name: 'index_product_attr_values_on_attr_id_and_value'
  end
end
