class UsersController < ApplicationController
  allow_unauthenticated_access only: [ :new, :create ]

  def new
    @user = User.new
  end

  def create
    Rails.logger.info("👤 [UsersController] Création utilisateur - email: #{user_params[:email_address]}, téléphone: #{user_params[:phone_number]}")
    result = Clients::RegistrationService.create(user_params)
    if result.success
      Rails.logger.info("✅ [UsersController] Utilisateur créé avec succès - user_id: #{result.user.id}, email: #{result.user.email_address}")
      # Stocker les infos pour la page de vérification
      session[:pending_verification_email] = result.user.email_address if result.user.email_address.present?
      session[:pending_verification_phone] = result.user.phone_number if result.user.phone_number.present?
      redirect_to new_client_verification_path,
                  notice: (result.errors.present? ? "Compte créé, envoi du code échoué" : "Compte créé. Vérifiez votre SMS pour le code.")
    else
      Rails.logger.warn("⚠️ [UsersController] Échec création utilisateur - erreurs: #{result.errors.full_messages.join(', ')}")
      @user = result.user
      render :new, status: :unprocessable_entity
    end
  end

  private
    def user_params
      params.require(:user).permit(:first_name, :last_name, :country_code, :phone_number, :email_address, :password, :password_confirmation)
    end
end
