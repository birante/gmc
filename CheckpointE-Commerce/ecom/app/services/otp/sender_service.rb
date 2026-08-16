# frozen_string_literal: true

module Otp
  class SenderService
    class << self
      # Envoie un code OTP par SMS
      # @param phone_number [String] Le numéro de téléphone (local ou international)
      # @param code [String] Le code OTP à envoyer
      # @param country_code [String] Code pays pour le formatage (défaut: 221 Sénégal)
      # @return [Boolean] true si l'envoi a réussi, false sinon
      def send_sms(phone_number, code, country_code: "221")
        start_time = Time.current
        Rails.logger.info("🚀 [Otp::SenderService] Début envoi OTP SMS")
        Rails.logger.info("📱 [Otp::SenderService] Phone: #{phone_number} | Country: +#{country_code}")

        sms_enabled = Sms::SmsService::SEND_SMS_ENABLED == "true"
        simulation_ok_in_dev = (Rails.env.development? || Rails.env.test?)

        Rails.logger.info("🔧 [Otp::SenderService] Config - SEND_SMS_ENABLED: #{sms_enabled} | Env: #{Rails.env}")

        if simulation_ok_in_dev
          Rails.logger.info("🔐 [Otp::SenderService] MODE DEV - Code OTP : #{code} pour #{phone_number}")
        end

        begin
          unless sms_enabled
            if simulation_ok_in_dev
              Rails.logger.warn("⚠️ [Otp::SenderService] SMS désactivé - Mode simulation (DEV uniquement, le code est loggué ci-dessus)")
              duration = (Time.current - start_time).round(3)
              Rails.logger.info("⏱️ [Otp::SenderService] Simulation terminée en #{duration}s")
              return true
            else
              Rails.logger.error("❌ [Otp::SenderService] SMS désactivé en production (SEND_SMS_ENABLED=#{Sms::SmsService::SEND_SMS_ENABLED}) - échec d'envoi")
              return false
            end
          end

          formatted_phone = format_phone_for_sms(phone_number, country_code)
          message = "Votre code de vérification aa : #{code}"

          Rails.logger.info("📱 [Otp::SenderService] Formatage - Original: #{phone_number} -> Formatted: #{formatted_phone}")
          Rails.logger.info("📊 [Otp::SenderService] Message - Length: #{message.length} chars | Type: verification")

          sms_message = Sms::SmsService.new.send_sms(
            to: formatted_phone,
            message: message,
            sms_type: "verification",
            validate_length: false
          )

          duration = (Time.current - start_time).round(3)
          if sms_message.status == "sent"
            Rails.logger.info("✅ [Otp::SenderService] SMS OTP envoyé avec succès - Phone: #{formatted_phone} | Duration: #{duration}s")
            return true
          end

          Rails.logger.error("❌ [Otp::SenderService] Échec envoi SMS OTP - Phone: #{formatted_phone} | Status: #{sms_message.status} | Duration: #{duration}s")
          false
        rescue Sms::SmsService::SmsDisabledError => e
          if simulation_ok_in_dev
            Rails.logger.warn("⚠️ [Otp::SenderService] Service SMS désactivé en dev - simulation OK : #{e.message}")
            true
          else
            Rails.logger.error("❌ [Otp::SenderService] Service SMS désactivé en production : #{e.message}")
            false
          end
        rescue => e
          duration = (Time.current - start_time).round(3)
          Rails.logger.error("❌ [Otp::SenderService] ERREUR envoi SMS OTP après #{duration}s")
          Rails.logger.error("❌ [Otp::SenderService] Phone: #{phone_number} | Error: #{e.class.name} - #{e.message}")
          Rails.logger.error("❌ [Otp::SenderService] Backtrace: #{e.backtrace.first(3).join("\n")}")
          false
        end
      end

      # Envoie un code OTP par email
      # @param email [String] L'adresse email
      # @param code [String] Le code OTP à envoyer
      # @return [Boolean] true si l'envoi a réussi, false sinon
      def send_email(email, code)
        start_time = Time.current
        Rails.logger.info("🚀 [Otp::SenderService] Début envoi OTP Email")
        Rails.logger.info("📧 [Otp::SenderService] Email: #{email} | Code: #{code}")

        begin
          # TODO: Créer un mailer pour l'envoi du code OTP
          # Pour l'instant, on log le code
          if Rails.env.development? || Rails.env.test?
            Rails.logger.info("🔐 [Otp::SenderService] MODE DEV - Code OTP : #{code} pour #{email}")
            duration = (Time.current - start_time).round(3)
            Rails.logger.info("⏱️ [Otp::SenderService] Simulation email terminée en #{duration}s")
            return true
          end

          # En production, utiliser un vrai mailer
          # Exemple:
          # OtpMailer.verification_code(email, code).deliver_now

          duration = (Time.current - start_time).round(3)
          Rails.logger.info("✅ [Otp::SenderService] Email OTP envoyé avec succès - Email: #{email} | Duration: #{duration}s")
          true
        rescue => e
          duration = (Time.current - start_time).round(3)
          Rails.logger.error("❌ [Otp::SenderService] ERREUR envoi email OTP après #{duration}s")
          Rails.logger.error("❌ [Otp::SenderService] Email: #{email} | Error: #{e.class.name} - #{e.message}")
          Rails.logger.error("❌ [Otp::SenderService] Backtrace: #{e.backtrace.first(3).join('\n')}")
          false
        end
      end

      private

      def format_phone_for_sms(phone_number, country_code)
        return phone_number.to_s.gsub(/\D/, "") if phone_number.blank?

        formatted = PhoneValidationService.formatted_number(phone_number, country_code)
        formatted.presence || "#{country_code}#{phone_number.to_s.gsub(/\D/, "")}"
      end
    end
  end
end
