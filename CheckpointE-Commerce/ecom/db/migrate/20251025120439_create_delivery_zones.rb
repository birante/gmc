class CreateDeliveryZones < ActiveRecord::Migration[8.0]
  def change
    create_table :delivery_zones do |t|
      t.string :name
      t.decimal :base_fee, precision: 8, scale: 2, default: 0.0
      t.integer :min_delivery_time, default: 0
      t.integer :max_delivery_time, default: 0
      t.boolean :is_active, default: false

      t.timestamps
    end
    add_index :delivery_zones, :name, unique: true
  end
end
