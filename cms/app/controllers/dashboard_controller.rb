class DashboardController < ApplicationController
  before_action :authenticate_user!

  def show
    @stats = {
      users:      User.count,
      posts:      Post.count,
      published:  Post.published.count,
      drafts:     Post.draft.count,
      comments:   Comment.count,
      pending:    Comment.pending.count,
      categories: Category.count,
      tags:       Tag.count,
    }
    @recent_posts    = Post.recent.limit(5)
    @recent_comments = Comment.recent.limit(5)
  end
end
