# frozen_string_literal: true

module Notifications
  # Notification de code de vérification OTP
  class VerificationCodeNotification < BaseNotification
    def initialize(recipient:, code:, channel: "sms", **options)
      super(recipient: recipient, **options)
      @code = code
      @channel = channel.to_s
    end

    def deliver
      results = {}

      # Si le canal est SMS, envoyer SMS avec fallback email
      if @channel == "sms"
        results[:sms] = deliver_sms
        # Si SMS échoue ou est désactivé, fallback vers email
        if (results[:sms].nil? || !results[:sms][:success]) && recipient_email.present?
          results[:email] = deliver_email
        end
      else
        # Si le canal est email, envoyer uniquement email
        results[:email] = deliver_email
      end

      results
    end

    protected

    def sms_message
      "Votre code de vérification: #{@code}"
    end

    def sms_type
      "verification"
    end

    def whatsapp_message
      "Votre code de vérification: #{@code}"
    end

    # Pour WhatsApp, on peut utiliser un template approuvé
    # Exemple: "verification_code" avec paramètres [@code]
    def whatsapp_template_name
      # TODO: Configurer le nom du template approuvé dans Meta Business
      # Exemple: "verification_code" ou "otp_verification"
      nil # Pour l'instant, on utilise le message texte libre
    end

    def whatsapp_template_params
      [ @code ]
    end

    def mailer_class
      if recipient.is_a?(User)
        ClientVerificationMailer
      elsif recipient.is_a?(Vendor)
        VendorVerificationMailer
      else
        nil
      end
    end

    def mailer_method
      :otp_email
    end

    def mailer_params
      if recipient.is_a?(User)
        { user: recipient, code: @code }
      elsif recipient.is_a?(Vendor)
        { vendor: recipient, code: @code }
      else
        {}
      end
    end

    def should_send_sms?
      @channel == "sms" && super
    end

    def should_send_email?
      @channel == "email" || (options.fetch(:send_email, true) && recipient_email.present?)
    end
  end
end
