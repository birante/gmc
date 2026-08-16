# frozen_string_literal: true

module Notifications
  # Notification de réinitialisation de mot de passe
  class PasswordResetNotification < BaseNotification
    def initialize(recipient:, reset_token:, reset_url:, **options)
      super(recipient: recipient, **options)
      @reset_token = reset_token
      @reset_url = reset_url
    end

    protected

    def sms_message
      "Reset mdp: #{@reset_url} (15 min). Ignorez si non demandé."
    end

    def sms_type
      "verification"
    end

    def whatsapp_message
      "Réinitialisation de mot de passe: #{@reset_url} (valide 15 min). Si vous n'avez pas demandé ce lien, ignorez ce message."
    end

    def mailer_class
      if recipient.is_a?(User)
        Client::PasswordsMailer
      elsif recipient.is_a?(Vendor)
        Vendors::PasswordsMailer
      else
        nil
      end
    end

    def mailer_method
      :reset
    end

    def mailer_params
      if recipient.is_a?(User)
        { user: recipient, token: @reset_token }
      elsif recipient.is_a?(Vendor)
        { vendor: recipient, token: @reset_token }
      else
        {}
      end
    end
  end
end
