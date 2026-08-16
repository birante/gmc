class CreatePendingRegistrations < ActiveRecord::Migration[8.0]
  def change
    create_table :pending_registrations do |t|
      t.string :user_type, null: false # 'User' ou 'Vendor'
      t.string :email
      t.string :phone_number
      t.text :encrypted_data, null: false # Données chiffrées du formulaire
      t.string :otp_code, null: false
      t.datetime :otp_expires_at, null: false
      t.datetime :verified_at
      t.string :channel # 'sms' ou 'email'

      t.timestamps
    end

    add_index :pending_registrations, :email
    add_index :pending_registrations, :phone_number
    add_index :pending_registrations, :otp_code
    add_index :pending_registrations, [ :user_type, :email ], name: "index_pending_reg_on_type_email"
    add_index :pending_registrations, [ :user_type, :phone_number ], name: "index_pending_reg_on_type_phone"
  end
end
