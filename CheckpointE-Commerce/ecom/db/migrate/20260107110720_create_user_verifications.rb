class CreateUserVerifications < ActiveRecord::Migration[8.0]
  def change
    create_table :user_verifications do |t|
      t.references :user, null: false, foreign_key: true
      t.string :code, null: false
      t.string :channel, null: false
      t.datetime :expires_at, null: false
      t.datetime :used_at
      t.boolean :status, null: false, default: false

      t.timestamps
    end

    add_index :user_verifications, [ :user_id, :code ]
    add_index :user_verifications, :status
  end
end
