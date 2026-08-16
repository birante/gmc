class CreateShopPaymentMethods < ActiveRecord::Migration[8.0]
  def change
    create_table :shop_payment_methods do |t|
      t.references :shop, null: false, foreign_key: true
      t.references :payment_method, null: false, foreign_key: true
      t.boolean :is_active, default: false

      t.timestamps
    end
  end
end
