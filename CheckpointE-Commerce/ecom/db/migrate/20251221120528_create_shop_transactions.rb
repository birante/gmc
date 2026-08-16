class CreateShopTransactions < ActiveRecord::Migration[8.0]
  def change
    create_table :shop_transactions do |t|
      t.references :shop, null: false, foreign_key: true
      t.references :order, null: false, foreign_key: true
      t.references :payout, null: false, foreign_key: true
      t.decimal :amount, precision: 10, scale: 2, default: 0.0
      t.references :currency, foreign_key: true
      t.string :transaction_type
      t.string :description
      t.jsonb :metadata

      t.timestamps
    end
  end
end
