class MigrateBlogPostContentToActionText < ActiveRecord::Migration[8.0]
  class MigrationBlogPost < ActiveRecord::Base
    self.table_name = "blog_posts"
  end

  def up
    return unless column_exists?(:blog_posts, :content)

    helpers = ActionController::Base.helpers

    MigrationBlogPost.where.not(content: [ nil, "" ]).find_each do |post|
      html = helpers.simple_format(post.content, {}, wrapper_tag: "p")
      execute ActiveRecord::Base.sanitize_sql_array([
        "INSERT INTO action_text_rich_texts (record_type, record_id, name, body, created_at, updated_at) " \
        "VALUES ('BlogPost', ?, 'content', ?, NOW(), NOW()) " \
        "ON CONFLICT (record_type, record_id, name) DO NOTHING",
        post.id, html
      ])
    end

    remove_column :blog_posts, :content
  end

  def down
    add_column :blog_posts, :content, :text unless column_exists?(:blog_posts, :content)

    rows = ActiveRecord::Base.connection.execute(
      "SELECT record_id, body FROM action_text_rich_texts " \
      "WHERE record_type = 'BlogPost' AND name = 'content'"
    )

    sanitizer = Rails::Html::FullSanitizer.new
    rows.each do |row|
      plain = sanitizer.sanitize(row["body"].to_s).strip
      execute ActiveRecord::Base.sanitize_sql_array([
        "UPDATE blog_posts SET content = ? WHERE id = ?",
        plain, row["record_id"]
      ])
    end

    execute "DELETE FROM action_text_rich_texts WHERE record_type = 'BlogPost' AND name = 'content'"
  end
end
