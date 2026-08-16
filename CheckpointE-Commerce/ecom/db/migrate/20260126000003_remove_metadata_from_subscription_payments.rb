class RemoveMetadataFromSubscriptionPayments < ActiveRecord::Migration[8.0]
  def change
    # Supprimer la colonne metadata si elle existe
    remove_column :subscription_payments, :metadata, :jsonb if column_exists?(:subscription_payments, :metadata)
  end
end
