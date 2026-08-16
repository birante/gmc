class CreateContactMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :contact_messages do |t|
      t.string :first_name, null: false
      t.string :last_name
      t.string :email
      t.string :phone
      t.string :subject
      t.text :message, null: false
      t.string :status, default: "new", null: false
      t.string :ip_address
      t.string :user_agent

      t.timestamps
    end

    add_index :contact_messages, :status
    add_index :contact_messages, :created_at
  end
end
