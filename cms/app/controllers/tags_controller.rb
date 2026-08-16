class TagsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]

  def index
    @tags = Tag.order(:name)
  end

  def show
    tag = Tag.friendly.find(params[:id])
    @tag = tag
    @posts = tag.posts.for_public.recent.page(params[:page]).per(12)
  end
end
