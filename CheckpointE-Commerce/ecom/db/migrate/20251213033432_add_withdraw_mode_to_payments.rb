class AddWithdrawModeToPayments < ActiveRecord::Migration[8.0]
  def change
    add_column :payments, :withdraw_mode, :string
  end
end
