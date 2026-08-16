class PasswordsController < ApplicationController
  allow_unauthenticated_access
  before_action :set_user_by_token, only: %i[ edit update ]
  before_action :set_vendor_by_token, only: %i[ edit update ]

  layout "client_onboarding", only: [ :new, :create, :edit, :update ]

  def new
  end

  def create
    Rails.logger.info("🔑 [PasswordsController] Demande reset password - email_client: #{params[:email_address]}, email_vendor: #{params[:email]}")
    user = User.find_by(email_address: params[:email_address])
    vendor = Vendor.find_by(email: params[:email])

    if user
      Rails.logger.info("📧 [PasswordsController] Reset password pour client - user_id: #{user.id}")
      PasswordsMailer.reset(user).deliver_later
      redirect_to new_client_session_path, notice: "Instructions de réinitialisation envoyées à votre adresse email."
    elsif vendor
      Rails.logger.info("📧 [PasswordsController] Reset password pour vendor - vendor_id: #{vendor.id}")
      PasswordsMailer.reset(vendor).deliver_later
      redirect_to new_vendors_session_path, notice: "Instructions de réinitialisation envoyées à votre adresse email."
    else
      Rails.logger.warn("⚠️ [PasswordsController] Aucun utilisateur trouvé pour reset password")
      # Si aucun utilisateur trouvé, rediriger vers la page client par défaut
      redirect_to new_client_session_path, notice: "Si cette adresse email existe, vous recevrez les instructions de réinitialisation."
    end
  end

  def edit
  end

  def update
    if @user&.update(password_params)
      Rails.logger.info("✅ [PasswordsController] Mot de passe réinitialisé avec succès - user_id: #{@user.id}")
      redirect_to new_client_session_path, notice: "Mot de passe réinitialisé avec succès."
    elsif @vendor&.update(password_params)
      Rails.logger.info("✅ [PasswordsController] Mot de passe réinitialisé avec succès - vendor_id: #{@vendor.id}")
      redirect_to new_vendors_session_path, notice: "Mot de passe réinitialisé avec succès."
    else
      Rails.logger.warn("⚠️ [PasswordsController] Échec réinitialisation mot de passe")
      redirect_to edit_password_path(params[:token]), alert: "Les mots de passe ne correspondent pas."
    end
  end

  private
    def password_params
      params.permit(:password, :password_confirmation)
    end

    def set_user_by_token
      @user = User.find_by_password_reset_token!(params[:token])
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      redirect_to new_password_path, alert: "Password reset link is invalid or has expired."
    end

    def set_vendor_by_token
      @vendor = Vendor.find_by_password_reset_token!(params[:token])
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      redirect_to new_password_path, alert: "Password reset link is invalid or has expired."
    end
end
