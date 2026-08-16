class CreateVendorVerifications < ActiveRecord::Migration[7.0]
  def change
    create_table :vendor_verifications do |t|
      t.references :vendor, null: false, foreign_key: true
      t.string :code, null: false
      t.string :channel, null: false
      t.datetime :expires_at, null: false
      t.datetime :used_at
      t.timestamps
    end

    add_index :vendor_verifications, [ :vendor_id, :code ]
  end
end
