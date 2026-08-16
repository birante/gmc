# frozen_string_literal: true

module Notifications
  # Classe de base pour toutes les notifications (SMS et Email)
  class BaseNotification
    attr_reader :recipient, :options

    def initialize(recipient:, **options)
      @recipient = recipient
      @options = options
    end

    # Envoie la notification via les canaux configurés
    def deliver
      results = {}
      results[:sms] = deliver_sms if should_send_sms?
      results[:whatsapp] = deliver_whatsapp if should_send_whatsapp?
      results[:email] = deliver_email if should_send_email?
      results
    end

    # Envoie uniquement le SMS
    def deliver_sms
      Rails.logger.info("📱 [Notifications::BaseNotification] deliver_sms appelé - notification: #{notification_name}, should_send_sms?: #{should_send_sms?}, recipient_phone: #{recipient_phone_number.inspect}")

      return nil unless should_send_sms?
      Rails.logger.warn("⚠️ [Notifications::BaseNotification] should_send_sms? retourne false - notification: #{notification_name}")
      return nil unless recipient_phone_number.present?
      Rails.logger.warn("⚠️ [Notifications::BaseNotification] recipient_phone_number absent - notification: #{notification_name}")

      message = sms_message
      return nil unless message.present?
      Rails.logger.warn("⚠️ [Notifications::BaseNotification] sms_message vide - notification: #{notification_name}")

      formatted_phone = formatted_phone_number
      Rails.logger.info("📱 [Notifications::BaseNotification] Envoi SMS - to: #{formatted_phone}, message length: #{message.length}, sms_type: #{sms_type}")

      begin
        result = Sms::SmsService.new.send_sms(
          to: formatted_phone,
          message: message,
          sms_type: sms_type,
          validate_length: sms_validate_length,
          max_segments: sms_max_segments
        )
        Rails.logger.info("✅ [Notifications::BaseNotification] SMS envoyé avec succès - notification: #{notification_name}, sms_message_id: #{result.id}")
        { success: true, message: "SMS envoyé avec succès", sms_message_id: result.id }
      rescue Sms::SmsService::SmsDisabledError => e
        Rails.logger.info("📱 [Notifications] SMS désactivé - #{notification_name}: #{e.message}")
        { success: false, reason: "sms_disabled", error: e.message }
      rescue StandardError => e
        Rails.logger.error("❌ [Notifications] Erreur envoi SMS - #{notification_name}: #{e.class} - #{e.message}")
        Rails.logger.error("❌ [Notifications] Backtrace: #{e.backtrace.first(10).join("\n")}")
        { success: false, error: e.message }
      end
    end

    # Envoie uniquement le WhatsApp
    def deliver_whatsapp
      return nil unless should_send_whatsapp?
      return nil unless recipient_phone_number.present?

      message = whatsapp_message
      return nil unless message.present?

      begin
        Whatsapp::WhatsappService.new.send_message(
          to: formatted_phone_number,
          message: message,
          template_name: whatsapp_template_name,
          template_params: whatsapp_template_params
        )
        { success: true, message: "WhatsApp envoyé avec succès" }
      rescue Whatsapp::WhatsappService::WhatsappDisabledError => e
        Rails.logger.info("💬 [Notifications] WhatsApp désactivé - #{notification_name}")
        { success: false, reason: "whatsapp_disabled" }
      rescue StandardError => e
        Rails.logger.error("❌ [Notifications] Erreur envoi WhatsApp - #{notification_name}: #{e.message}")
        { success: false, error: e.message }
      end
    end

    # Envoie uniquement l'email
    def deliver_email
      return nil unless should_send_email?
      return nil unless recipient_email.present?

      begin
        mailer_class.with(mailer_params).public_send(mailer_method).deliver_later
        { success: true, message: "Email envoyé avec succès" }
      rescue StandardError => e
        Rails.logger.error("❌ [Notifications] Erreur envoi email - #{notification_name}: #{e.message}")
        { success: false, error: e.message }
      end
    end

    protected

    # Méthodes à surcharger dans les sous-classes

    # Le nom de la notification (pour le logging)
    def notification_name
      self.class.name.demodulize.underscore
    end

    # Le message SMS à envoyer (retourne nil si pas de SMS)
    def sms_message
      nil
    end

    # Le type de SMS (verification, notification, alert)
    def sms_type
      "notification"
    end

    # Valide la longueur du SMS
    def sms_validate_length
      true
    end

    # Nombre maximum de segments autorisés
    def sms_max_segments
      3
    end

    # Le message WhatsApp à envoyer (retourne nil si pas de WhatsApp)
    def whatsapp_message
      nil
    end

    # Le nom du template WhatsApp (optionnel, pour messages template)
    def whatsapp_template_name
      nil
    end

    # Les paramètres du template WhatsApp (optionnel)
    def whatsapp_template_params
      []
    end

    # La classe du mailer à utiliser
    def mailer_class
      raise NotImplementedError, "#{self.class} doit implémenter mailer_class"
    end

    # La méthode du mailer à appeler
    def mailer_method
      raise NotImplementedError, "#{self.class} doit implémenter mailer_method"
    end

    # Les paramètres à passer au mailer
    def mailer_params
      {}
    end

    # Détermine si on doit envoyer un SMS
    def should_send_sms?
      options.fetch(:send_sms, true)
    end

    # Détermine si on doit envoyer un WhatsApp
    def should_send_whatsapp?
      options.fetch(:send_whatsapp, false)
    end

    # Détermine si on doit envoyer un email
    def should_send_email?
      options.fetch(:send_email, true)
    end

    # Numéro de téléphone du destinataire
    def recipient_phone_number
      recipient.respond_to?(:phone_number) ? recipient.phone_number : nil
    end

    # Email du destinataire
    def recipient_email
      if recipient.respond_to?(:email_address)
        recipient.email_address
      elsif recipient.respond_to?(:email)
        recipient.email
      else
        nil
      end
    end

    # Numéro de téléphone formaté
    def formatted_phone_number
      if recipient.respond_to?(:formatted_phone_number)
        recipient.formatted_phone_number
      else
        recipient_phone_number
      end
    end
  end
end
