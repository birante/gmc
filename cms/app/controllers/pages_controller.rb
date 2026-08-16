class PagesController < ApplicationController
  def home
    @featured_posts = Post.for_public.featured.recent.limit(3)
    @recent_posts   = Post.for_public.recent.limit(9)
    @categories     = Category.roots.where(active: true).order(:display_order)
  end
end
