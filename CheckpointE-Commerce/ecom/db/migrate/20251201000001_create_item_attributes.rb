class CreateItemAttributes < ActiveRecord::Migration[7.0]
  def change
    create_table :item_attributes do |t|
      t.references :item, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :position, default: 0

      t.timestamps
    end

    add_index :item_attributes, [ :item_id, :name ], unique: true
  end
end
