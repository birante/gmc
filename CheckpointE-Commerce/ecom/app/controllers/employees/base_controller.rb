module Employees
  class BaseController < ApplicationController
    include EmployeeShopContext

    layout "employee"

    # Rendre les helpers collaborateur (url_with_shop, etc.) disponibles dans les contrôleurs
    helper EmployeesHelper
    include EmployeesHelper

    before_action :authenticate_employee!
    before_action :set_employee_for_view

    private

    def authenticate_employee!
      unless employee_signed_in?
        redirect_to new_employees_session_path, alert: t("employees.authentication.must_be_logged_in")
      end
    end

    def require_permission(permission_method)
      unless current_employee.send(permission_method)
        redirect_to employees_dashboard_path, alert: t("employees.authentication.no_permission")
      end
    end

    def set_employee_for_view
      @employee = current_employee
      @vendor = current_employee&.vendor
      @shops = current_employee.shops.order(created_at: :desc)
    end

    helper_method :current_employee_or_vendor

    def current_employee_or_vendor
      current_employee&.vendor
    end
  end
end
