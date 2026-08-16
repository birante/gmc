class AddMetadataToSubscriptionPayments < ActiveRecord::Migration[8.0]
  def up
    # Cette migration est dépréciée, utiliser withdraw_mode directement
    # Migration 20260126_add_withdraw_mode_to_subscription_payments.rb à la place
  end

  def down
    # N/A
  end
end
