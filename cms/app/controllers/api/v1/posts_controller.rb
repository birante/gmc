class Api::V1::PostsController < Api::V1::BaseController
  def index
    scope = Post.for_public.includes(:author, :category, :tags).recent
    posts = paginate(scope)
    render json: {
      posts: posts.map { |p| serialize(p) },
      meta:  { page: posts.current_page, total_pages: posts.total_pages, total: posts.total_count }
    }
  end

  def show
    post = Post.friendly.find(params[:id])
    render json: serialize(post, full: true)
  end

  private
  def serialize(post, full: false)
    base = {
      id: post.id, slug: post.slug, title: post.title, excerpt: post.excerpt_or_snippet,
      status: post.status, published_at: post.published_at, reading_time: post.reading_time,
      author: post.author && { id: post.author_id, name: post.author.full_name },
      category: post.category && { id: post.category_id, name: post.category.name, slug: post.category.slug },
      tags: post.tags.map { |t| { name: t.name, slug: t.slug } },
    }
    base.merge!(content: post.content, view_count: post.view_count, like_count: post.like_count) if full
    base
  end
end
