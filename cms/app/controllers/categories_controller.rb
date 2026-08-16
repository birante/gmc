class CategoriesController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_category, only: [:show, :edit, :update, :destroy]

  def index
    @categories = Category.roots.order(:display_order, :name)
  end

  def show
    @posts = Post.for_public.where(category_id: @category.id).recent.page(params[:page]).per(12)
  end

  def new
    @category = Category.new; authorize @category
  end

  def create
    @category = Category.new(category_params); authorize @category
    if @category.save
      redirect_to categories_path, notice: "Category created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; authorize @category; end

  def update
    authorize @category
    if @category.update(category_params)
      redirect_to categories_path, notice: "Category updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @category
    @category.destroy
    redirect_to categories_path, notice: "Category deleted."
  end

  private
  def set_category = @category = Category.friendly.find(params[:id])
  def category_params
    params.require(:category).permit(:name, :description, :parent_id, :display_order, :active)
  end
end
