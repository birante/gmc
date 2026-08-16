module Vendors
  class PasswordsMailer < ApplicationMailer
    def reset(vendor, token)
      @vendor = vendor
      @token = token
      Rails.logger.info("📧 [Vendors::PasswordsMailer] Envoi email reset password - vendor_id: #{vendor.id}, email: #{vendor.email}")
      mail subject: "Réinitialisation de votre mot de passe", to: vendor.email
    end
  end
end
