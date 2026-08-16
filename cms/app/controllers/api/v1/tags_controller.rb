class Api::V1::TagsController < Api::V1::BaseController
  def index
    render json: Tag.order(:name).map { |t| { name: t.name, slug: t.slug } }
  end
  def show
    render json: Tag.friendly.find(params[:id]).slice(:id, :name, :slug, :description)
  end
end
