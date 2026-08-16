class CreateCurrencies < ActiveRecord::Migration[8.0]
  def change
    create_table :currencies do |t|
      t.string :code, limit: 3
      t.string :symbol, limit: 10
      t.string :name
      t.string :thousands_separator, limit: 1
      t.string :decimal_separator, limit: 1
      t.boolean :symbol_precedes_amount
      t.boolean :is_active

      t.timestamps
    end
    add_index :currencies, :code, unique: true
  end
end
