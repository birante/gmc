class AddColorMetadataToAttributeValues < ActiveRecord::Migration[8.0]
  def change
    add_column :attribute_values, :hex_code, :string, limit: 7
    add_reference :attribute_values, :shop_color, foreign_key: true, index: true, null: true
  end
end
