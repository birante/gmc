class CreateDeliverySlots < ActiveRecord::Migration[8.0]
  def change
    create_table :delivery_slots do |t|
      t.time :start_time
      t.time :end_time
      t.boolean :is_active, default: false

      t.timestamps
    end
  end
end
