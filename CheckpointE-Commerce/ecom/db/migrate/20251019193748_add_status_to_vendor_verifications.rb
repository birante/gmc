class AddStatusToVendorVerifications < ActiveRecord::Migration[7.0]
  def change
    add_column :vendor_verifications, :status, :boolean, null: false, default: false
    add_index :vendor_verifications, :status
  end
end
