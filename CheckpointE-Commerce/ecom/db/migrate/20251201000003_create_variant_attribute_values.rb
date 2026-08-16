class CreateVariantAttributeValues < ActiveRecord::Migration[7.0]
  def change
    create_table :variant_attribute_values do |t|
      t.references :item_variant, null: false, foreign_key: true
      t.references :attribute_value, null: false, foreign_key: true

      t.timestamps
    end

    add_index :variant_attribute_values, [ :item_variant_id, :attribute_value_id ], unique: true, name: 'index_variant_attribute_values_unique'
  end
end
