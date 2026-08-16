class PostsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_post, only: [:show, :edit, :update, :destroy]

  def index
    scope = user_signed_in? && current_user.can_moderate? ? Post.all : Post.for_public
    @q = scope.ransack(params[:q])
    @posts = @q.result(distinct: true).includes(:author, :category, :tags).recent.page(params[:page]).per(12)
    @categories = Category.roots.where(active: true).order(:display_order)
  end

  def show
    @post.increment!(:view_count) if @post.published?
    @related = Post.for_public.where(category_id: @post.category_id).where.not(id: @post.id).recent.limit(3)
  end

  def new
    @post = Post.new(author: current_user)
    authorize @post
  end

  def create
    @post = Post.new(post_params.merge(author: current_user))
    authorize @post
    assign_tags(@post)
    if @post.save
      redirect_to @post, notice: "Post created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @post
  end

  def update
    authorize @post
    assign_tags(@post)
    if @post.update(post_params)
      redirect_to @post, notice: "Post updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @post
    @post.destroy
    redirect_to posts_url, notice: "Post deleted."
  end

  private

  def set_post
    @post = Post.friendly.find(params[:id])
  end

  def post_params
    params.require(:post).permit(:title, :content, :excerpt, :category_id, :status,
                                 :featured_image, :meta_title, :meta_description,
                                 :meta_keywords, :is_featured, :allow_comments)
  end

  def assign_tags(post)
    tag_names = params.dig(:post, :tag_names).to_s.split(",").map(&:strip).reject(&:blank?)
    return if tag_names.blank?
    post.tags = tag_names.map { |n| Tag.find_or_create_by(name: n) }
  end
end
