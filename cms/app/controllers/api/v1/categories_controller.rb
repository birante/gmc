class Api::V1::CategoriesController < Api::V1::BaseController
  def index
    render json: Category.roots.order(:display_order, :name).map { |c| { id: c.id, name: c.name, slug: c.slug } }
  end
  def show
    render json: Category.friendly.find(params[:id]).slice(:id, :name, :slug, :description)
  end
end
