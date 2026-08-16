# frozen_string_literal: true

class BlogPostsController < ApplicationController
  allow_unauthenticated_access

  before_action :set_categories
  before_action :set_post, only: [ :show ]
  before_action :set_active_category, only: [ :index, :category ]

  PER_PAGE = 13

  def index
    @posts = base_scope.page(params[:page]).per(PER_PAGE)
    @featured = @posts.first
    @other_posts = @posts.offset(1)
  end

  def category
    @active_category = BlogCategory.active.friendly.find(params[:slug])
    @posts = base_scope.where(blog_category_id: @active_category.id)
                       .page(params[:page]).per(PER_PAGE)
    @featured = @posts.first
    @other_posts = @posts.offset(1)
    render :index
  end

  def show
    BlogPost.where(id: @post.id).update_all("views_count = views_count + 1")

    @related_posts = BlogPost.published
                             .recent
                             .where.not(id: @post.id)
                             .where(blog_category_id: @post.blog_category_id)
                             .limit(4)
  end

  private

  def base_scope
    BlogPost.published
            .recent
            .includes(:blog_category, cover_image_attachment: :blob)
  end

  def set_categories
    @blog_categories = BlogCategory.active.ordered
  end

  def set_active_category
    @active_category ||= nil
  end

  def set_post
    @post = BlogPost.published.friendly.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    raise ActionController::RoutingError, "Article non trouvé"
  end
end
