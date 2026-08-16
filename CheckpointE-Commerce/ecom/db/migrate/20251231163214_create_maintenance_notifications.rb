class CreateMaintenanceNotifications < ActiveRecord::Migration[8.0]
  def change
    create_table :maintenance_notifications do |t|
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :email, null: false
      t.string :phone_number, null: false
      t.string :country_code, null: false
      t.string :user_type, null: false
      t.datetime :notified_at

      t.timestamps
    end

    add_index :maintenance_notifications, :email, unique: true
    add_index :maintenance_notifications, :phone_number
    add_index :maintenance_notifications, :user_type
  end
end
