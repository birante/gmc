module Employees
  class SessionsController < ApplicationController
    allow_unauthenticated_access only: [ :new, :create ]
    layout "employee_public"

    def new
      # Page de connexion
      redirect_to employees_dashboard_path if employee_signed_in?
    end

    def create
      Rails.logger.info("[Employees::SessionsController] Tentative de connexion collaborateur - email: #{params[:email]}")
      employee = Employee.find_by(email: params[:email])

      if employee&.authenticate(params[:password])
        if employee.active?
          Rails.logger.info("[Employees::SessionsController] Connexion collaborateur réussie - employee_id: #{employee.id}, email: #{employee.email}")
          # Terminer toute session existante (client ou vendeur)
          terminate_session if Current.session

          # Créer une nouvelle session pour le collaborateur
          start_new_session_for(employee)

          redirect_to employees_dashboard_path, notice: t("employees.sessions.create.success", name: employee.first_name)
        else
          Rails.logger.warn("[Employees::SessionsController] Compte collaborateur désactivé - employee_id: #{employee.id}")
          flash.now[:alert] = t("employees.sessions.create.account_disabled")
          render :new, status: :unprocessable_entity
        end
      else
        Rails.logger.warn("[Employees::SessionsController] Échec de connexion collaborateur - email: #{params[:email]}")
        flash.now[:alert] = t("employees.sessions.create.failure")
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      employee_id = Current.session&.sessionable_id
      Rails.logger.info("[Employees::SessionsController] Déconnexion collaborateur - employee_id: #{employee_id}")
      terminate_session
      redirect_to new_employees_session_path, notice: t("employees.sessions.destroy.success")
    end
  end
end
