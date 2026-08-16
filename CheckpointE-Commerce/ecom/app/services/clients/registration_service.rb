# frozen_string_literal: true

module Clients
  # Service d'enregistrement des clients en 2 étapes avec vérification OTP
  #
  # Processus:
  #   1. create(attrs, channel) - Crée un PendingRegistration et envoie l'OTP
  #   2. verify(pending, code) - Vérifie l'OTP et crée le compte User
  #
  # Usage:
  #   result = Clients::RegistrationService.create({
  #     first_name: "John",
  #     last_name: "Doe",
  #     email_address: "john@example.com",
  #     phone_number: "776857298",
  #     country_code: "SN",
  #     password: "secure123"
  #   }, "sms")
  #
  #   if result.success
  #     # Rediriger vers page de vérification OTP
  #     pending_id = result.pending_registration.id
  #   end
  #
  #   # Puis vérifier le code OTP
  #   verify_result = Clients::RegistrationService.verify(pending_id, "1234")
  #   if verify_result.success
  #     user = verify_result.user # Compte créé et vérifié
  #   end
  #
  # @see PendingRegistration
  # @see User
  class RegistrationService
    Result = Struct.new(:success, :user, :errors, :pending_registration)

    # Étape 1: Créer un enregistrement pending et envoyer l'OTP
    # Le compte User n'est PAS créé à cette étape
    def self.create(attrs, channel = nil)
      Rails.logger.info("📝 [Clients::RegistrationService] Début enregistrement pending - email: #{attrs[:email_address]}, téléphone: #{attrs[:phone_number]}, channel: #{channel}")
      channel ||= Rails.application.config.user_otp.default_channel

      # Vérifier les doublons dans les comptes existants
      if attrs[:email_address].present? && User.exists?(email_address: attrs[:email_address].strip.downcase)
        Rails.logger.warn("⚠️ [Clients::RegistrationService] Email déjà utilisé - email: #{attrs[:email_address]}")
        user = User.new(attrs)
        user.errors.add(:email_address, "est déjà utilisé")
        return Result.new(false, user, user.errors, nil)
      end

      if attrs[:phone_number].present? && User.exists?(phone_number: attrs[:phone_number].to_s.gsub(/\D/, ""))
        Rails.logger.warn("⚠️ [Clients::RegistrationService] Téléphone déjà utilisé - phone: #{attrs[:phone_number]}")
        user = User.new(attrs)
        user.errors.add(:phone_number, "est déjà utilisé")
        return Result.new(false, user, user.errors, nil)
      end

      # Valider les données AVANT de créer le pending registration
      user = User.new(attrs)
      unless user.valid?
        Rails.logger.warn("⚠️ [Clients::RegistrationService] Données invalides - erreurs: #{user.errors.full_messages.join(', ')}")
        return Result.new(false, user, user.errors, nil)
      end

      # Nettoyer les anciens pending registrations pour cet email/téléphone
      PendingRegistration.for_user
        .where("email = ? OR phone_number = ?", attrs[:email_address], attrs[:phone_number])
        .destroy_all

      # Créer un enregistrement pending avec OTP
      config = Rails.application.config.user_otp
      code = Otp::Generator.generate_from_config(config)
      ttl = Otp::Generator.ttl_from_config(config)

      pending = PendingRegistration.create!(
        user_type: "User",
        email: attrs[:email_address],
        phone_number: attrs[:phone_number],
        encrypted_data: attrs.to_json,
        otp_code: code,
        otp_expires_at: Time.current + ttl,
        channel: channel
      )

      # Envoyer l'OTP
      begin
        send_otp(pending, code, channel)
        Rails.logger.info("📧 [Clients::RegistrationService] OTP envoyé - pending_id: #{pending.id}, channel: #{channel}")
        Result.new(true, user, nil, pending)
      rescue => e
        Rails.logger.error("❌ [Clients::RegistrationService] OTP send failed: #{e.class} #{e.message}")
        pending.destroy
        user.errors.add(:base, "Envoi du code impossible")
        Result.new(false, user, user.errors, nil)
      end
    rescue => e
      Rails.logger.error("❌ [Clients::RegistrationService] unexpected error: #{e.class} #{e.message}")
      Result.new(false, user || User.new, [ e.message ], nil)
    end

    # Étape 2: Vérifie l'OTP et CRÉE le compte User
    # @param pending_or_identifier [PendingRegistration, Integer, String] ID ou email ou téléphone
    # @param code [String] Code OTP à vérifier
    # @return [Result] Objet Result avec success (boolean), user (User), errors (Array)
    def self.verify(pending_or_identifier, code)
      Rails.logger.info("🔐 [Clients::RegistrationService] Tentative de vérification OTP - code: #{code}")

      # Chercher le pending registration
      pending = find_pending_registration(pending_or_identifier)

      unless pending
        Rails.logger.warn("⚠️ [Clients::RegistrationService] Enregistrement pending non trouvé")
        return Result.new(false, nil, [ "pending_registration_not_found" ], nil)
      end

      # Vérifier si expiré
      if pending.expired?
        Rails.logger.warn("⚠️ [Clients::RegistrationService] Code expiré - pending_id: #{pending.id}")
        return Result.new(false, nil, [ "code_expired" ], pending)
      end

      # Vérifier le code
      unless pending.otp_code == code.to_s
        Rails.logger.warn("⚠️ [Clients::RegistrationService] Code invalide - pending_id: #{pending.id}")
        return Result.new(false, nil, [ "invalid_code" ], pending)
      end

      # Créer le compte utilisateur maintenant que l'OTP est validé
      attrs = JSON.parse(pending.encrypted_data, symbolize_names: true)

      # Double vérification des doublons (au cas où créé entre temps)
      if attrs[:email_address].present? && User.exists?(email_address: attrs[:email_address].strip.downcase)
        Rails.logger.error("❌ [Clients::RegistrationService] Email créé entre temps - email: #{attrs[:email_address]}")
        user = User.new(attrs)
        user.errors.add(:email_address, "est déjà utilisé")
        return Result.new(false, user, user.errors, pending)
      end

      user = User.new(attrs)

      if user.save
        pending.mark_as_verified!

        # Créer le UserVerification pour marquer l'utilisateur comme vérifié
        user.user_verifications.create!(
          code: pending.otp_code,
          channel: pending.channel,
          expires_at: pending.otp_expires_at,
          used_at: Time.current,
          status: true
        )

        Rails.logger.info("✅ [Clients::RegistrationService] User créé après vérification OTP - user_id: #{user.id}")
        Result.new(true, user, nil, pending)
      else
        Rails.logger.error("❌ [Clients::RegistrationService] Échec création user après OTP - erreurs: #{user.errors.full_messages.join(', ')}")
        Result.new(false, user, user.errors, pending)
      end
    rescue => e
      Rails.logger.error("❌ [Clients::RegistrationService] verify error: #{e.class} #{e.message}")
      Result.new(false, nil, [ e.message ], pending)
    end

    private

    # Trouve un PendingRegistration par ID, email ou téléphone
    # @param identifier [PendingRegistration, Integer, String] Identifiant à rechercher
    # @return [PendingRegistration, nil] Enregistrement trouvé ou nil
    def self.find_pending_registration(identifier)
      if identifier.is_a?(PendingRegistration)
        identifier
      elsif identifier.is_a?(Integer)
        PendingRegistration.find_by(id: identifier, user_type: "User")
      else
        # Chercher par email ou téléphone
        PendingRegistration.active.for_user.find_by(email: identifier) ||
          PendingRegistration.active.for_user.find_by(phone_number: identifier)
      end
    end

    # Envoie l'OTP par le canal approprié (SMS ou Email)
    # @param pending [PendingRegistration] Enregistrement pending
    # @param code [String] Code OTP à envoyer
    # @param channel [String] Canal d'envoi ("sms" ou "email")
    def self.send_otp(pending, code, channel)
      start_time = Time.current
      # TTL en minutes
      ttl_minutes = ((pending.otp_expires_at - Time.current) / 60).to_i

      Rails.logger.info("🚀 [Clients::RegistrationService] ========== ENVOI OTP ==========")
      Rails.logger.info("📋 [Clients::RegistrationService] Pending ID: #{pending.id} | Channel: #{channel} | TTL: #{ttl_minutes}min")
      Rails.logger.info("👤 [Clients::RegistrationService] Email: #{pending.email.presence || 'N/A'} | Phone: #{pending.phone_number.presence || 'N/A'}")

      # Fallback vers email si pas de téléphone pour SMS
      if channel.to_s == "sms" && !pending.phone_number.present?
        Rails.logger.warn("⚠️ [Clients::RegistrationService] Pas de numéro de téléphone, fallback vers email")
        channel = "email"
      end

      # Vérifier qu'on a un moyen de contacter
      if channel.to_s == "email" && !pending.email.present?
        Rails.logger.error("❌ [Clients::RegistrationService] Aucun moyen de contacter l'utilisateur")
        raise StandardError, "Aucun moyen de contacter l'utilisateur"
      end

      # Afficher le code OTP uniquement en développement (SÉCURITÉ: ne jamais logger en production)
      if Rails.env.development?
        Rails.logger.info("🔐 [DEV ONLY] CODE OTP: #{code} | Expires: #{pending.otp_expires_at.strftime('%H:%M:%S')}")
        puts "\n" + "=" * 70
        puts "🔑 CODE OTP CLIENT: #{code}"
        puts "📧 Email: #{pending.email}" if pending.email.present?
        puts "📱 Téléphone: #{pending.phone_number}" if pending.phone_number.present?
        puts "⏰ Canal: #{channel} | Valide: #{ttl_minutes} minutes | Expire à: #{pending.otp_expires_at.strftime('%H:%M:%S')}"
        puts "=" * 70 + "\n"
      else
        Rails.logger.info("🔐 [Clients::RegistrationService] OTP généré - ID: #{pending.id} | Channel: #{channel} | TTL: #{ttl_minutes}min")
      end

      # Envoyer l'OTP par le canal approprié et vérifier le résultat
      send_start = Time.current
      sent = if channel.to_s == "sms"
        country_code = pending.registration_data&.dig(:country_code).presence || "221"
        Rails.logger.info("📱 [Clients::RegistrationService] Envoi OTP par SMS - Phone: #{pending.phone_number} | Country: +#{country_code}")
        Otp::SenderService.send_sms(pending.phone_number, code, country_code: country_code)
      else
        Rails.logger.info("📧 [Clients::RegistrationService] Envoi OTP par Email - Email: #{pending.email}")
        Otp::SenderService.send_email(pending.email, code)
      end

      send_duration = (Time.current - send_start).round(3)
      total_duration = (Time.current - start_time).round(3)

      unless sent
        Rails.logger.error("❌ [Clients::RegistrationService] Envoi OTP échoué - channel: #{channel} | Send: #{send_duration}s")
        raise StandardError, "Échec d'envoi du code OTP par #{channel}"
      end

      Rails.logger.info("✅ [Clients::RegistrationService] OTP envoyé avec succès - Send: #{send_duration}s | Total: #{total_duration}s")
    end

    # Test helper method - not for production use
    def self.generate_otp_code_with_length(length)
      Otp::Generator.generate(length: length)
    end
  end
end
