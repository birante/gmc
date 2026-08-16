class MakeOrderAndPayoutOptionalInShopTransactions < ActiveRecord::Migration[8.0]
  def up
    # Supprimer les contraintes de clé étrangère existantes
    remove_foreign_key :shop_transactions, :orders if foreign_key_exists?(:shop_transactions, column: :order_id)
    remove_foreign_key :shop_transactions, :payouts if foreign_key_exists?(:shop_transactions, column: :payout_id)

    # Rendre order_id optionnel (null: true)
    change_column_null :shop_transactions, :order_id, true

    # Rendre payout_id optionnel (null: true)
    change_column_null :shop_transactions, :payout_id, true

    # Ajouter les clés étrangères avec on_delete: :nullify pour permettre null
    add_foreign_key :shop_transactions, :orders, column: :order_id, on_delete: :nullify
    add_foreign_key :shop_transactions, :payouts, column: :payout_id, on_delete: :nullify
  end

  def down
    # Supprimer les clés étrangères
    remove_foreign_key :shop_transactions, column: :order_id if foreign_key_exists?(:shop_transactions, column: :order_id)
    remove_foreign_key :shop_transactions, column: :payout_id if foreign_key_exists?(:shop_transactions, column: :payout_id)

    # Rendre les colonnes non-nullable (mais il faut d'abord remplir les valeurs null)
    # Note: Cette migration down peut échouer si des valeurs null existent
    change_column_null :shop_transactions, :order_id, false, 0
    change_column_null :shop_transactions, :payout_id, false, 0

    # Réajouter les clés étrangères
    add_foreign_key :shop_transactions, :orders, column: :order_id
    add_foreign_key :shop_transactions, :payouts, column: :payout_id
  end
end
