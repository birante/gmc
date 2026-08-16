class PasswordsMailer < ApplicationMailer
  def reset(user)
    @user = user
    Rails.logger.info("📧 [PasswordsMailer] Envoi email reset password - user_id: #{@user.id}, email: #{user.email_address}")
    mail subject: "Reset your password", to: user.email_address
  end
end
