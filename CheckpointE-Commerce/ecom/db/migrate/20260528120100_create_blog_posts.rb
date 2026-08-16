class CreateBlogPosts < ActiveRecord::Migration[8.0]
  def change
    create_table :blog_posts do |t|
      t.string :title, null: false
      t.string :slug, null: false
      t.string :excerpt
      t.text :content
      t.string :author_name
      t.string :status, default: "draft", null: false
      t.datetime :published_at
      t.references :blog_category, null: true, foreign_key: true
      t.integer :views_count, default: 0, null: false

      t.timestamps
    end

    add_index :blog_posts, :slug, unique: true
    add_index :blog_posts, :status
    add_index :blog_posts, :published_at
  end
end
