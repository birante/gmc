module Client
  # Mailer de reset de mot de passe — canal **opportuniste** côté client.
  # Le canal primaire reste le SMS (l'email est optionnel pour les utilisateurs clients).
  # Quand l'utilisateur a renseigné un email, on lui envoie le même code OTP en parallèle.
  class PasswordsMailer < ApplicationMailer
    def reset(user, code: nil)
      @user = user
      @code = code
      Rails.logger.info("📧 [Client::PasswordsMailer] Envoi email reset password (OTP) - user_id: #{user.id}, email: #{user.email_address}")
      mail subject: "Réinitialisation de votre mot de passe", to: user.email_address
    end
  end
end
