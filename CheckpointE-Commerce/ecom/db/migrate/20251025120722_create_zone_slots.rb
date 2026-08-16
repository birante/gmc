class CreateZoneSlots < ActiveRecord::Migration[8.0]
  def change
    create_table :zone_slots do |t|
      t.references :delivery_zone, null: false, foreign_key: true
      t.references :delivery_slot, null: false, foreign_key: true

      t.timestamps
    end
  end
end
