class ApplicationController < ActionController::Base
  # Modern Rails browser detection
  allow_browser versions: :modern

  # Devise: expose extra params on sign-up (first_name, last_name)
  before_action :configure_permitted_parameters, if: :devise_controller?

  # Global error handler for authorization
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  include Pundit::Authorization

  helper_method :current_user_can_moderate?

  private

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:first_name, :last_name])
    devise_parameter_sanitizer.permit(:account_update, keys: [:first_name, :last_name, :bio])
  end

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_back(fallback_location: root_path)
  end

  def current_user_can_moderate?
    user_signed_in? && current_user.can_moderate?
  end
end
