class CreatePayments < ActiveRecord::Migration[8.0]
  def change
    create_table :payments do |t|
      t.references :order, null: false, foreign_key: true
      t.references :payment_method, null: false, foreign_key: true
      t.string :transaction_id
      t.integer :status
      t.decimal :amount
      t.datetime :paid_at
      t.integer :user_id

      t.timestamps
    end
    add_index :payments, :transaction_id, unique: true
  end
end
