class CreateOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :orders do |t|
      t.references :user, null: false, foreign_key: true
      t.references :delivery_zone, null: false, foreign_key: true
      t.references :delivery_slot, null: false, foreign_key: true
      t.string :status
      t.decimal :total_amount
      t.decimal :delivery_fee
      t.decimal :final_amount
      t.references :currency, null: false, foreign_key: true
      t.text :delivery_address
      t.text :notes

      t.timestamps
    end
  end
end
