class AddWithdrawModeToSubscriptionPayments < ActiveRecord::Migration[8.0]
  def change
    # Vérifier que la table existe
    return unless table_exists?(:subscription_payments)

    # Ajouter les colonnes si elles n'existent pas
    add_column :subscription_payments, :withdraw_mode, :string unless column_exists?(:subscription_payments, :withdraw_mode)
    add_column :subscription_payments, :payment_type, :string, default: "PAR" unless column_exists?(:subscription_payments, :payment_type)
  end
end
