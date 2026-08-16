class CreateComments < ActiveRecord::Migration[8.1]
  def change
    create_table :comments do |t|
      t.references :post, null: false, foreign_key: true
      t.references :user, null: true, foreign_key: true
      t.references :parent, null: true, foreign_key: { to_table: :comments }
      t.text :content, null: false
      t.integer :status, null: false, default: 0     # 0=pending 1=approved 2=spam 3=trash
      t.string :ip_address
      t.text :user_agent

      t.timestamps
    end
    add_index :comments, :status
  end
end
