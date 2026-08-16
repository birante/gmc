class AddBalanceToShops < ActiveRecord::Migration[8.0]
  def change
    add_column :shops, :balance, :decimal, precision: 10, scale: 2, default: 0.0

    # Ajouter la référence à currency (sans default en migration, on utilise un after_create dans le modèle)
    add_reference :shops, :currency, foreign_key: true
  end
end
