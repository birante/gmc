module Vendors
  # Service d'enregistrement des vendeurs en 2 étapes avec vérification OTP
  #
  # Processus:
  #   1. create(attrs, channel) - Crée un PendingRegistration et envoie l'OTP
  #   2. verify(pending, code) - Vérifie l'OTP et crée le compte Vendor
  #
  # Usage:
  #   result = Vendors::RegistrationService.create({
  #     first_name: "Marie",
  #     last_name: "Diop",
  #     email: "marie@shop.sn",
  #     phone_number: "779876543",
  #     country_code: "221",
  #     password: "secure123"
  #   }, "sms")
  #
  #   if result.success
  #     # Rediriger vers page de vérification OTP
  #     pending_id = result.pending_registration.id
  #   end
  #
  #   # Puis vérifier le code OTP
  #   verify_result = Vendors::RegistrationService.verify(pending_id, "1234")
  #   if verify_result.success
  #     vendor = verify_result.vendor # Compte créé et vérifié
  #   end
  #
  # @see PendingRegistration
  # @see Vendor
  class RegistrationService
    Result = Struct.new(:success, :vendor, :errors, :pending_registration)

    # Etape 1: Creer un enregistrement pending et envoyer l'OTP
    # Le compte Vendor n'est PAS cree a cette etape
    def self.create(attrs, channel = nil)
      start_time = Time.current
      Rails.logger.info("🚀 [Vendors::RegistrationService] ========== INSCRIPTION VENDEUR ===========")
      Rails.logger.info("📋 [Vendors::RegistrationService] Email: #{attrs[:email]} | Phone: #{attrs[:phone_number]}")

      # Verifier les doublons dans les comptes existants
      if attrs[:email].present? && Vendor.exists?(email: attrs[:email].strip.downcase)
        Rails.logger.warn("⚠️ [Vendors::RegistrationService] Email déjà utilisé - #{attrs[:email]}")
        vendor = Vendor.new(attrs)
        vendor.errors.add(:email, "est deja utilise")
        duration = (Time.current - start_time).round(3)
        Rails.logger.warn("⏱️ [Vendors::RegistrationService] Échec après #{duration}s - Email doublon")
        return Result.new(false, vendor, vendor.errors, nil)
      end

      if attrs[:phone_number].present? && Vendor.exists?(phone_number: attrs[:phone_number].to_s.gsub(/\D/, ""))
        Rails.logger.warn("⚠️ [Vendors::RegistrationService] Téléphone déjà utilisé - #{attrs[:phone_number]}")
        vendor = Vendor.new(attrs)
        vendor.errors.add(:phone_number, "est deja utilise")
        duration = (Time.current - start_time).round(3)
        Rails.logger.warn("⏱️ [Vendors::RegistrationService] Échec après #{duration}s - Téléphone doublon")
        return Result.new(false, vendor, vendor.errors, nil)
      end

      # Utiliser SMS par defaut si le vendeur a un numero de telephone
      channel ||= (attrs[:phone_number].present? ? "sms" : Rails.application.config.vendor_otp.default_channel)
      Rails.logger.info("📡 [Vendors::RegistrationService] Canal sélectionné: #{channel}")

      # Valider les donnees AVANT de creer le pending registration
      vendor = Vendor.new(attrs)
      unless vendor.valid?
        Rails.logger.warn("⚠️ [Vendors::RegistrationService] Données invalides - #{vendor.errors.full_messages.join(', ')}")
        duration = (Time.current - start_time).round(3)
        Rails.logger.warn("⏱️ [Vendors::RegistrationService] Échec après #{duration}s - Validation échouée")
        return Result.new(false, vendor, vendor.errors, nil)
      end
      Rails.logger.info("✅ [Vendors::RegistrationService] Données validées avec succès")

      # Nettoyer les anciens pending registrations pour cet email/telephone
      old_count = PendingRegistration.for_vendor
        .where("email = ? OR phone_number = ?", attrs[:email], attrs[:phone_number])
        .destroy_all.count
      Rails.logger.info("🧹 [Vendors::RegistrationService] #{old_count} ancien(s) pending supprimé(s)") if old_count > 0

      # Creer un enregistrement pending avec OTP
      config = Rails.application.config.vendor_otp
      code = Otp::Generator.generate_from_config(config)
      ttl = Otp::Generator.ttl_from_config(config)
      ttl_minutes = (ttl / 60).to_i
      Rails.logger.info("🔐 [Vendors::RegistrationService] Code OTP généré - Length: #{code.length} | TTL: #{ttl_minutes}min")

      pending = PendingRegistration.create!(
        user_type: "Vendor",
        email: attrs[:email],
        phone_number: attrs[:phone_number],
        encrypted_data: attrs.to_json,
        otp_code: code,
        otp_expires_at: Time.current + ttl,
        channel: channel
      )

      # Envoyer l'OTP
      begin
        send_start = Time.current
        send_otp(pending, code, channel)
        send_duration = (Time.current - send_start).round(3)
        total_duration = (Time.current - start_time).round(3)
        Rails.logger.info("✅ [Vendors::RegistrationService] OTP envoyé - Pending #{pending.id} | Channel: #{channel} | Send: #{send_duration}s | Total: #{total_duration}s")
        Result.new(true, vendor, nil, pending)
      rescue => e
        duration = (Time.current - start_time).round(3)
        Rails.logger.error("❌ [Vendors::RegistrationService] ÉCHEC envoi OTP après #{duration}s - #{e.class}: #{e.message}")
        Rails.logger.error("❌ [Vendors::RegistrationService] Backtrace: #{e.backtrace.first(3).join('\n')}")
        pending.destroy
        vendor.errors.add(:base, "Envoi du code impossible")
        Result.new(false, vendor, vendor.errors, nil)
      end
    rescue => e
      duration = (Time.current - start_time).round(3)
      Rails.logger.error("❌ [Vendors::RegistrationService] EXCEPTION après #{duration}s - #{e.class}: #{e.message}")
      Rails.logger.error("❌ [Vendors::RegistrationService] Backtrace: #{e.backtrace.first(5).join('\n')}")
      Result.new(false, vendor || Vendor.new, [ e.message ], nil)
    end

    # Etape 2: Verifier l'OTP et CREER le compte Vendor
    def self.verify(pending_or_identifier, code)
      start_time = Time.current
      # SECURITE: Ne pas logger le code OTP
      Rails.logger.info("🚀 [Vendors::RegistrationService] ========== VÉRIFICATION OTP VENDEUR ==========")

      # Chercher le pending registration
      pending = find_pending_registration(pending_or_identifier)

      unless pending
        duration = (Time.current - start_time).round(3)
        Rails.logger.warn("⚠️ [Vendors::RegistrationService] Pending non trouvé après #{duration}s")
        return Result.new(false, nil, [ "pending_registration_not_found" ], nil)
      end

      Rails.logger.info("📋 [Vendors::RegistrationService] Pending trouvé - ID: #{pending.id} | Email: #{pending.email} | Phone: #{pending.phone_number}")

      # Verifier si expire
      if pending.expired?
        duration = (Time.current - start_time).round(3)
        Rails.logger.warn("⚠️ [Vendors::RegistrationService] Code expiré après #{duration}s - Pending: #{pending.id}")
        return Result.new(false, nil, [ "code_expired" ], pending)
      end

      # Verifier le code (comparaison securisee)
      unless ActiveSupport::SecurityUtils.secure_compare(pending.otp_code.to_s, code.to_s)
        duration = (Time.current - start_time).round(3)
        Rails.logger.warn("⚠️ [Vendors::RegistrationService] Code invalide après #{duration}s - Pending: #{pending.id}")
        return Result.new(false, nil, [ "invalid_code" ], pending)
      end

      Rails.logger.info("✅ [Vendors::RegistrationService] Code OTP valide")

      # Parser les donnees stockees
      attrs = JSON.parse(pending.encrypted_data, symbolize_names: true)

      # Cas 1: Login d'un vendor existant (vendor_id present)
      if attrs[:vendor_id].present?
        vendor = Vendor.find_by(id: attrs[:vendor_id])
        unless vendor
          Rails.logger.error("[Vendors::RegistrationService] Vendor introuvable - vendor_id: #{attrs[:vendor_id]}")
          return Result.new(false, nil, [ "vendor_not_found" ], pending)
        end

        pending.mark_as_verified!

        # Activer le vendor et creer la verification
        vendor.update!(status: :active)
        vendor.vendor_verifications.create!(
          code: pending.otp_code,
          channel: pending.channel,
          expires_at: pending.otp_expires_at,
          used_at: Time.current,
          status: true
        )

        duration = (Time.current - start_time).round(3)
        Rails.logger.info("✅ [Vendors::RegistrationService] Vendor existant vérifié en #{duration}s - ID: #{vendor.id}")
        return Result.new(true, vendor, nil, pending)
      end

      # Cas 2: Creation d'un nouveau vendor (inscription)
      Rails.logger.info("👤 [Vendors::RegistrationService] Création nouveau compte vendeur...")

      # Double verification des doublons (au cas ou cree entre temps)
      if attrs[:email].present? && Vendor.exists?(email: attrs[:email].strip.downcase)
        duration = (Time.current - start_time).round(3)
        Rails.logger.error("❌ [Vendors::RegistrationService] Email créé entre-temps après #{duration}s")
        vendor = Vendor.new(attrs)
        vendor.errors.add(:email, "est deja utilise")
        return Result.new(false, vendor, vendor.errors, pending)
      end

      vendor = Vendor.new(attrs)
      vendor.status = :active # Activer directement apres verification OTP
      Rails.logger.info("📝 [Vendors::RegistrationService] Vendor préparé - Email: #{vendor.email}")

      if vendor.save
        pending.mark_as_verified!

        # Creer le VendorVerification pour marquer le vendor comme verifie
        vendor.vendor_verifications.create!(
          code: pending.otp_code,
          channel: pending.channel,
          expires_at: pending.otp_expires_at,
          used_at: Time.current,
          status: true
        )

        duration = (Time.current - start_time).round(3)
        Rails.logger.info("✅ [Vendors::RegistrationService] Vendor créé et vérifié en #{duration}s - ID: #{vendor.id} | Email: #{vendor.email}")
        Result.new(true, vendor, nil, pending)
      else
        duration = (Time.current - start_time).round(3)
        Rails.logger.error("❌ [Vendors::RegistrationService] Échec création vendor après #{duration}s - #{vendor.errors.full_messages.join(', ')}")
        Result.new(false, vendor, vendor.errors, pending)
      end
    rescue => e
      duration = (Time.current - start_time).round(3)
      Rails.logger.error("❌ [Vendors::RegistrationService] EXCEPTION verify après #{duration}s - #{e.class}: #{e.message}")
      Rails.logger.error("❌ [Vendors::RegistrationService] Backtrace: #{e.backtrace.first(5).join('\n')}")
      Result.new(false, nil, [ e.message ], pending)
    end

    private

    def self.find_pending_registration(identifier)
      if identifier.is_a?(PendingRegistration)
        identifier
      elsif identifier.is_a?(Integer)
        PendingRegistration.find_by(id: identifier, user_type: "Vendor")
      else
        # Chercher par email ou telephone
        PendingRegistration.active.for_vendor.find_by(email: identifier) ||
          PendingRegistration.active.for_vendor.find_by(phone_number: identifier)
      end
    end

    def self.send_otp(pending, code, channel)
      start_time = Time.current
      # TTL en minutes
      ttl_minutes = ((pending.otp_expires_at - Time.current) / 60).to_i

      Rails.logger.info("🚀 [Vendors::RegistrationService] ========== ENVOI OTP VENDEUR ===========")
      Rails.logger.info("📋 [Vendors::RegistrationService] Pending ID: #{pending.id} | Channel: #{channel} | TTL: #{ttl_minutes}min")
      Rails.logger.info("👤 [Vendors::RegistrationService] Email: #{pending.email.presence || 'N/A'} | Phone: #{pending.phone_number.presence || 'N/A'}")

      # Fallback vers email si pas de telephone pour SMS
      if channel.to_s == "sms" && !pending.phone_number.present?
        Rails.logger.warn("⚠️ [Vendors::RegistrationService] Pas de téléphone, fallback vers email")
        channel = "email"
      end

      # Verifier qu'on a un moyen de contacter
      if channel.to_s == "email" && !pending.email.present?
        Rails.logger.error("❌ [Vendors::RegistrationService] Aucun moyen de contacter le vendeur")
        raise StandardError, "Aucun moyen de contacter le vendeur"
      end

      # Afficher le code OTP uniquement en developpement (SECURITE: ne jamais logger en production)
      if Rails.env.development?
        Rails.logger.info("🔐 [DEV ONLY] CODE OTP: #{code} | Expires: #{pending.otp_expires_at.strftime('%H:%M:%S')}")
        puts "\n" + "=" * 70
        puts "🔑 CODE OTP VENDEUR: #{code}"
        puts "📧 Email: #{pending.email}" if pending.email.present?
        puts "📱 Téléphone: #{pending.phone_number}" if pending.phone_number.present?
        puts "⏰ Canal: #{channel} | Valide: #{ttl_minutes} minutes | Expire à: #{pending.otp_expires_at.strftime('%H:%M:%S')}"
        puts "=" * 70 + "\n"
      else
        Rails.logger.info("🔐 [Vendors::RegistrationService] OTP généré - ID: #{pending.id} | Channel: #{channel} | TTL: #{ttl_minutes}min")
      end

      # Envoyer l'OTP par le canal approprie
      send_start = Time.current
      if channel.to_s == "sms"
        country_code = pending.registration_data&.dig(:country_code).presence || "221"
        Rails.logger.info("📱 [Vendors::RegistrationService] Envoi OTP par SMS - Phone: #{pending.phone_number} | Country: +#{country_code}")
        Otp::SenderService.send_sms(pending.phone_number, code, country_code: country_code)
      else
        Rails.logger.info("📧 [Vendors::RegistrationService] Envoi OTP par Email - Email: #{pending.email}")
        Otp::SenderService.send_email(pending.email, code)
      end

      send_duration = (Time.current - send_start).round(3)
      total_duration = (Time.current - start_time).round(3)
      Rails.logger.info("✅ [Vendors::RegistrationService] OTP envoyé avec succès - Send: #{send_duration}s | Total: #{total_duration}s")
    end

    # Test helper method - not for production use
    def self.generate_otp_code_with_length(length)
      Otp::Generator.generate(length: length)
    end
  end
end
