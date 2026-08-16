# frozen_string_literal: true

module Admin
  class SessionsController < ActionController::Base
    layout "admin_login"

    skip_before_action :set_locale, raise: false

    def new
      # Déjà connecté → redirection vers ActiveAdmin
      redirect_to main_app.admin_root_path and return if current_admin_user.present?
      @admin_user = AdminUser.new
    end

    def create
      email = params[:email].to_s.strip.downcase.presence
      admin_user = AdminUser.find_by(email: email)
      if admin_user&.authenticate(params[:password])
        session[:admin_user_id] = admin_user.id
        # Redirection vers le tableau de bord ActiveAdmin (/admin)
        redirect_to main_app.admin_root_path, notice: t("active_admin.devise.sessions.signed_in", default: "Connexion réussie.")
      else
        @admin_user = AdminUser.new(email: params[:email])
        flash.now[:alert] = t("active_admin.devise.failure.invalid", default: "Email ou mot de passe incorrect.")
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      session.delete(:admin_user_id)
      redirect_to new_admin_user_session_path, notice: t("active_admin.devise.sessions.signed_out", default: "Déconnexion réussie.")
    end

    private

    def current_admin_user
      return nil unless session[:admin_user_id].present?
      @current_admin_user ||= AdminUser.find_by(id: session[:admin_user_id])
    end
    helper_method :current_admin_user
  end
end
