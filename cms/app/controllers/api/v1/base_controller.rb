class Api::V1::BaseController < ActionController::API
  private
  def paginate(scope)
    page = (params[:page] || 1).to_i
    per  = [[(params[:per_page] || 20).to_i, 1].max, 100].min
    scope.page(page).per(per)
  end
end
