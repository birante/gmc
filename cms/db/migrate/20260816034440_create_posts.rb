class CreatePosts < ActiveRecord::Migration[8.1]
  def change
    create_table :posts do |t|
      t.string  :title, null: false
      t.string  :slug, null: false
      t.text    :content
      t.text    :excerpt
      t.references :author, null: true, foreign_key: { to_table: :users }
      t.references :category, null: true, foreign_key: true
      t.integer :status, null: false, default: 0    # 0=draft 1=published 2=archived
      t.string  :featured_image
      t.integer :view_count, null: false, default: 0
      t.integer :like_count, null: false, default: 0
      t.string  :meta_title
      t.text    :meta_description
      t.string  :meta_keywords
      t.boolean :is_featured, null: false, default: false
      t.boolean :allow_comments, null: false, default: true
      t.integer :reading_time
      t.datetime :published_at

      t.timestamps
    end
    add_index :posts, :slug, unique: true
    add_index :posts, :status
    add_index :posts, :is_featured
    add_index :posts, :published_at
  end
end
