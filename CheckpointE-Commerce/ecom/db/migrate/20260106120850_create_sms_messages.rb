class CreateSmsMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :sms_messages do |t|
      t.string :from
      t.string :to, null: false
      t.text :body, null: false
      t.string :status, null: false, default: "pending"
      t.string :sms_type
      t.string :provider
      t.jsonb :provider_response, default: {}

      t.timestamps
    end

    add_index :sms_messages, :to
    add_index :sms_messages, :status
    add_index :sms_messages, :provider
    add_index :sms_messages, :created_at
  end
end
