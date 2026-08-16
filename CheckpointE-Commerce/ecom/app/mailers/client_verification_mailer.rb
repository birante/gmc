# frozen_string_literal: true

class ClientVerificationMailer < ApplicationMailer
  def otp_email(user = nil, code = nil)
    @user = user || params[:user]
    @code = code || params[:code]

    unless @user.email_address.present?
      Rails.logger.error("❌ [ClientVerificationMailer] Pas d'email pour user_id: #{@user.id}")
      return
    end

    Rails.logger.info("📧 [ClientVerificationMailer] Envoi email OTP - user_id: #{@user.id}, email: #{@user.email_address}, code: #{@code}")
    mail(to: @user.email_address, subject: "Votre code de validation (#{Rails.application.config.user_otp.length} digits)")
  end
end
