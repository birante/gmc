module Client
  # Mot de passe oublié — flux 3 étapes (SMS-first, email opportuniste).
  #
  # Étape 1 : new + create
  #   - Le user saisit son téléphone.
  #   - On génère un OTP (4 chiffres, configurable via Rails.application.config.user_otp).
  #   - On envoie l'OTP par SMS (canal primaire et obligatoire côté client).
  #   - Si l'utilisateur a renseigné un email, on l'envoie aussi en parallèle (canal opportuniste).
  #
  # Étape 2 : verify + check_otp
  #   - Le user saisit le code reçu.
  #   - Si OK, on émet un reset_token HMAC court-vivant (15 min) stocké en session, et on redirige vers edit.
  #
  # Étape 3 : edit + update
  #   - Le user saisit son nouveau mot de passe.
  #   - On vérifie le reset_token, on bcrypt-hash le mdp, on log out les autres sessions, on connecte le user.
  class PasswordsController < ApplicationController
    allow_unauthenticated_access

    layout "client_onboarding"

    RESET_TOKEN_TTL = 15.minutes
    RESET_TOKEN_PURPOSE = "client_password_reset"

    # Étape 1a — formulaire de saisie du téléphone
    def new
    end

    # Étape 1b — création de l'OTP + envoi SMS
    def create
      phone = params[:phone_number].to_s.strip
      country_code = params[:country_code].to_s.strip

      user = User.find_by(phone_number: phone, country_code: country_code) if phone.present?

      if user.nil? || user.phone_number.blank?
        # Anti-énumération : UX strictement identique au cas légitime.
        # On pose un état "dummy" en session ; verify rendra le formulaire OTP,
        # check_otp renverra "code invalide" pour toute saisie.
        Rails.logger.info("🔍 [Client::PasswordsController] Tentative de reset pour téléphone inconnu - phone: #{phone}, country_code: #{country_code}")
        clear_pending_reset_state
        session[:password_reset_pending_dummy_at] = Time.current.to_i
        session[:password_reset_pending_masked_phone] = masked_phone(phone)
        redirect_to client_verify_password_path,
                    notice: "Si ce numéro existe, un code de vérification vient d'être envoyé par SMS au #{masked_phone(phone)}."
        return
      end

      sent = generate_and_send_otp(user)

      if sent
        clear_pending_reset_state
        session[:password_reset_pending_user_id] = user.id
        session[:password_reset_pending_at] = Time.current.to_i
        Rails.logger.info("🔑 [Client::PasswordsController] OTP envoyé - user_id: #{user.id}")
        redirect_to client_verify_password_path,
                    notice: "Un code de vérification vient d'être envoyé par SMS au #{masked_phone(user.phone_number)}."
      else
        Rails.logger.error("❌ [Client::PasswordsController] Échec envoi OTP - user_id: #{user.id}")
        flash.now[:alert] = "Erreur lors de l'envoi du SMS. Veuillez réessayer dans quelques instants."
        render :new, status: :unprocessable_entity
      end
    end

    # Étape 2a — formulaire de saisie de l'OTP
    def verify
      if current_pending_user
        @masked_phone = masked_phone(current_pending_user.phone_number)
      elsif pending_dummy_active?
        @masked_phone = session[:password_reset_pending_masked_phone].to_s
      else
        redirect_to client_new_password_path, alert: "Veuillez d'abord saisir votre numéro de téléphone."
      end
    end

    # Étape 2b — vérification de l'OTP, émission du reset_token
    def check_otp
      user = current_pending_user

      # Cas dummy (téléphone inconnu) : anti-énumération, on simule un échec OTP.
      if user.nil? && pending_dummy_active?
        @masked_phone = session[:password_reset_pending_masked_phone].to_s
        flash.now[:alert] = "Code invalide ou expiré. Veuillez réessayer ou demander un nouveau code."
        render :verify, status: :unprocessable_entity
        return
      end

      unless user
        redirect_to client_new_password_path, alert: "La session a expiré. Veuillez recommencer."
        return
      end

      code = combined_otp_code
      verification = user.user_verifications.active.find_by(code: code) if code.present?

      if verification.nil? || verification.expired?
        Rails.logger.warn("⚠️ [Client::PasswordsController] Code invalide ou expiré - user_id: #{user.id}")
        @masked_phone = masked_phone(user.phone_number)
        flash.now[:alert] = "Code invalide ou expiré. Veuillez réessayer ou demander un nouveau code."
        render :verify, status: :unprocessable_entity
        return
      end

      # OTP validé : on consomme la verification et on émet un reset_token signé.
      verification.mark_used!
      session[:password_reset_token] = build_reset_token(user)
      clear_pending_reset_state

      Rails.logger.info("✅ [Client::PasswordsController] OTP validé - user_id: #{user.id}, redirection vers étape 3")
      redirect_to client_edit_password_path
    end

    # Étape 3a — formulaire du nouveau mot de passe
    def edit
      @user = user_from_reset_token(session[:password_reset_token])
      unless @user
        redirect_to client_new_password_path, alert: "La session de réinitialisation a expiré. Veuillez recommencer."
      end
    end

    # Étape 3b — sauvegarde du nouveau mot de passe
    def update
      @user = user_from_reset_token(session[:password_reset_token])

      unless @user
        redirect_to client_new_password_path, alert: "La session de réinitialisation a expiré. Veuillez recommencer."
        return
      end

      if @user.update(password_params)
        Rails.logger.info("✅ [Client::PasswordsController] Mot de passe réinitialisé - user_id: #{@user.id}")

        # Invalider TOUTES les sessions actives de cet utilisateur (sécurité : on suppose le
        # mot de passe potentiellement compromis), puis ouvrir une nouvelle session fraîche.
        @user.sessions.destroy_all if @user.respond_to?(:sessions)

        # Consommer le reset_token et toute session vendor concurrente.
        session.delete(:password_reset_token)
        session.delete(:vendor_id)

        start_new_session_for(@user)
        current_cart # déclenche la fusion du panier invité si nécessaire

        redirect_to client_dashboard_path,
                    notice: "Mot de passe réinitialisé avec succès. Vous êtes maintenant connecté."
      else
        flash.now[:alert] = @user.errors.full_messages.join(", ")
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def password_params
      params.require(:user).permit(:password, :password_confirmation)
    end

    # Récupère le user de l'étape 1, à partir de la session — pour l'étape 2.
    def current_pending_user
      user_id = session[:password_reset_pending_user_id]
      pending_at = session[:password_reset_pending_at].to_i
      return nil unless user_id.present? && pending_at.positive?

      # 15 min de validité pour la session intermédiaire entre étape 1 et 2.
      return nil if Time.current.to_i - pending_at > RESET_TOKEN_TTL.to_i

      User.find_by(id: user_id)
    end

    # État "dummy" actif : utilisateur inconnu mais on simule un parcours OTP normal
    # pour ne pas leaker l'existence d'un compte. TTL identique au flux légitime.
    def pending_dummy_active?
      dummy_at = session[:password_reset_pending_dummy_at].to_i
      return false unless dummy_at.positive?
      return false if Time.current.to_i - dummy_at > RESET_TOKEN_TTL.to_i

      true
    end

    def clear_pending_reset_state
      session.delete(:password_reset_pending_user_id)
      session.delete(:password_reset_pending_at)
      session.delete(:password_reset_pending_dummy_at)
      session.delete(:password_reset_pending_masked_phone)
    end

    # Génère un OTP, l'enregistre comme UserVerification, et envoie SMS (+ email opportuniste).
    # @return [Boolean] true si SMS envoyé avec succès.
    def generate_and_send_otp(user)
      # Invalider tout code actif précédent (anti-rejeu, force le user à utiliser le dernier code).
      user.user_verifications.active.update_all(expires_at: Time.current - 1.second)

      config = Rails.application.config.user_otp
      code = Otp::Generator.generate_from_config(config)
      ttl = Otp::Generator.ttl_from_config(config)

      user.user_verifications.create!(
        code: code,
        channel: "sms",
        expires_at: Time.current + ttl,
        status: false
      )

      if Rails.env.development?
        puts "\n" + "=" * 70
        puts "🔑 CODE OTP CLIENT (reset mdp): #{code}"
        puts "📱 Téléphone: #{user.phone_number}"
        puts "📧 Email: #{user.email_address}" if user.email_address.present?
        puts "⏰ Valide: #{(ttl / 60).to_i} minutes"
        puts "=" * 70 + "\n"
      end

      sms_ok = Otp::SenderService.send_sms(
        user.phone_number, code, country_code: user.country_code.presence || "221"
      )

      # Email opportuniste : envoi en parallèle UNIQUEMENT si l'utilisateur a un email.
      # Le critère de succès reste le SMS (l'email est optionnel côté client).
      # On encapsule dans rescue pour qu'un échec mail n'impacte jamais le retour SMS.
      if user.email_address.present?
        begin
          Client::PasswordsMailer.reset(user, code: code).deliver_later
        rescue => e
          Rails.logger.error("⚠️ [Client::PasswordsController] Échec email opportuniste (non bloquant) - user_id: #{user.id}, error: #{e.class} #{e.message}")
        end
      end

      sms_ok
    end

    # Combine les champs du formulaire OTP (champ unique `code` ou champs `otp_code_0`, `otp_code_1`, ...).
    def combined_otp_code
      if params[:code].present?
        params[:code].to_s.strip
      else
        digits = (0..5).map { |i| params["otp_code_#{i}"] }.compact.reject(&:blank?)
        digits.join.strip
      end
    end

    # Reset token = HMAC signé contenant user_id + horodatage.
    # On utilise des clés string (pas symbole) car le sérialiseur par défaut de
    # MessageVerifier est JSON : symboles → strings au round-trip.
    def build_reset_token(user)
      Rails.application.message_verifier(RESET_TOKEN_PURPOSE)
           .generate({ "user_id" => user.id, "ts" => Time.current.to_i })
    end

    def user_from_reset_token(token)
      return nil if token.blank?

      data = Rails.application.message_verifier(RESET_TOKEN_PURPOSE).verify(token)
      return nil unless data.is_a?(Hash)

      user_id = data["user_id"] || data[:user_id]
      ts = data["ts"] || data[:ts]
      return nil if user_id.blank? || ts.blank?
      return nil if Time.current.to_i - ts.to_i > RESET_TOKEN_TTL.to_i

      User.find_by(id: user_id)
    rescue ActiveSupport::MessageVerifier::InvalidSignature, ArgumentError
      nil
    end

    def masked_phone(phone)
      return "" if phone.blank?
      digits = phone.to_s.gsub(/\D/, "")
      return phone if digits.length < 4
      "#{digits[0..1]}#{"*" * (digits.length - 4)}#{digits[-2..]}"
    end
  end
end
