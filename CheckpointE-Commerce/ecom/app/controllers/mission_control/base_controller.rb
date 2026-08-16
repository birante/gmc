# frozen_string_literal: true

module MissionControl
  class BaseController < ApplicationController
    # Skip the default authentication from ApplicationController
    skip_before_action :require_authentication

    # Still resume session to get current_user/current_employee/current_vendor
    before_action :resume_session_for_mission_control

    # Custom authentication for Mission Control
    before_action :authenticate_for_mission_control

    private

    def resume_session_for_mission_control
      # Resume session without requiring authentication
      Current.session ||= find_session_by_cookie
    end

    def find_session_by_cookie
      Session.find_by(id: cookies.signed[:session_id]) if cookies.signed[:session_id]
    end

    def authenticate_for_mission_control
      unless current_employee.present? || current_vendor.present?
        # Store the return URL
        session[:return_to_after_authenticating] = request.url

        # Redirect to employee login (preferred for admin tools)
        redirect_to new_employees_session_path, alert: "Vous devez vous connecter pour accéder à Mission Control Jobs."
      end
    end
  end
end
