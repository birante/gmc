class CreatePayouts < ActiveRecord::Migration[8.0]
  def change
    create_table :payouts do |t|
      t.references :shop, null: false, foreign_key: true
      t.decimal :amount, precision: 10, scale: 2, default: 0.0
      t.references :currency, foreign_key: true
      t.string :status
      t.string :reference_number
      t.datetime :paid_at
      t.integer :payout_month
      t.integer :payout_year

      t.timestamps
    end
  end
end
