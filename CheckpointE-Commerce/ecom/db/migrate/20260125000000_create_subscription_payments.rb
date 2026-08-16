class CreateSubscriptionPayments < ActiveRecord::Migration[7.1]
  def change
    create_table :subscription_payments do |t|
      t.references :shop, null: false, foreign_key: true
      t.references :plan, null: false, foreign_key: true
      t.references :payment_method, null: false, foreign_key: true

      t.decimal :amount, precision: 15, scale: 2, null: false
      t.string :status, default: "pending", null: false
      t.string :withdraw_mode, null: false  # Mode de paiement (wave-senegal, orange-money-senegal, etc.)
      t.string :payment_type, default: "PAR"  # Type de paiement Paydunya (PAR ou PSR)

      # Paydunya specifics
      t.string :paydunya_token
      t.string :paydunya_invoice_url
      t.string :transaction_id
      t.datetime :paid_at

      # Store response for debugging
      t.json :provider_response

      # Reason for failure
      t.text :failure_reason

      t.timestamps
    end

    add_index :subscription_payments, :paydunya_token
    add_index :subscription_payments, :transaction_id
  end
end
