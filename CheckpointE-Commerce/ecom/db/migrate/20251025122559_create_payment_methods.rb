class CreatePaymentMethods < ActiveRecord::Migration[8.0]
  def change
    create_table :payment_methods do |t|
      t.string :code
      t.string :name
      t.string :provider
      t.string :method_type
      t.boolean :is_active, default: false

      t.timestamps
    end
    add_index :payment_methods, :code, unique: true
  end
end
