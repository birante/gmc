class CreateReviews < ActiveRecord::Migration[8.0]
  def change
    create_table :reviews do |t|
      t.references :user, null: false, foreign_key: true
      t.references :item, null: false, foreign_key: true
      t.references :order_item, null: true, foreign_key: true
      t.integer :rating, null: false
      t.text :comment
      t.string :status, default: "pending", null: false
      t.integer :helpful_count, default: 0, null: false

      t.timestamps
    end

    # Index unique pour s'assurer qu'un client ne peut laisser qu'un seul avis par produit
    add_index :reviews, [ :user_id, :item_id ], unique: true, name: "index_reviews_on_user_id_and_item_id"
    add_index :reviews, :status
    add_index :reviews, :rating
    add_index :reviews, :created_at
  end
end
