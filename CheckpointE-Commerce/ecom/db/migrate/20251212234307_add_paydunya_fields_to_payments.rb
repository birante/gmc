class AddPaydunyaFieldsToPayments < ActiveRecord::Migration[8.0]
  def change
    add_column :payments, :paydunya_token, :string
    add_column :payments, :paydunya_invoice_url, :string
    add_column :payments, :payment_type, :string
    add_column :payments, :provider_response, :jsonb
  end
end
