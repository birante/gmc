class CreateAttributeValues < ActiveRecord::Migration[7.0]
  def change
    create_table :attribute_values do |t|
      t.references :item_attribute, null: false, foreign_key: true
      t.string :value, null: false
      t.integer :position, default: 0

      t.timestamps
    end

    add_index :attribute_values, [ :item_attribute_id, :value ], unique: true
  end
end
