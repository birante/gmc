module Client
  class SessionsController < ApplicationController
    allow_unauthenticated_access only: [ :new, :create ]

    layout "client_onboarding", only: [ :new, :create ]

    def new
      # Sauvegarder l'URL de retour si fournie en paramètre (validation contre Open Redirect)
      if params[:return_to].present? && safe_redirect_url?(params[:return_to])
        session[:return_to] = params[:return_to]
      end
    end

    def create
      Rails.logger.info("🔐 [Client::SessionsController] Tentative de connexion client - téléphone: #{params[:phone_number]}, code pays: #{params[:country_code]}")
      user = User.find_by(phone_number: params[:phone_number], country_code: params[:country_code])

      if user&.authenticate(params[:password])
        Rails.logger.info("✅ [Client::SessionsController] Connexion client réussie - user_id: #{user.id}, téléphone: #{user.phone_number}")
        # Terminer toute session vendor existante
        session.delete(:vendor_id)

        start_new_session_for(user)
        current_cart # déclenche la fusion du panier invité si nécessaire

        # Vérifier si le compte est vérifié
        unless user.verified?
          Rails.logger.info("⚠️ [Client::SessionsController] Compte non vérifié - génération d'un nouveau code OTP - user_id: #{user.id}")
          regenerate_verification_otp(user)
          # Sauvegarder l'URL de retour pour rediriger après vérification
          session[:return_to_after_verification] = session.delete(:return_to) || client_cart_path
          # Stocker les infos pour la page de vérification
          session[:pending_verification_email] = user.email_address if user.email_address.present?
          session[:pending_verification_phone] = user.phone_number if user.phone_number.present?
          redirect_to new_client_verification_path, alert: "Vous devez vérifier votre compte avant de continuer."
          return
        end

        # Rediriger vers la page d'origine ou le panier
        return_path = session.delete(:return_to) || client_cart_path
        redirect_to return_path, notice: "Connexion réussie!"
      else
        Rails.logger.warn("⚠️ [Client::SessionsController] Échec de connexion client - téléphone: #{params[:phone_number]}")
        flash.now[:alert] = "Numéro de téléphone ou mot de passe incorrect"
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      user_id = current_user&.id
      Rails.logger.info("🔓 [Client::SessionsController] Déconnexion client - user_id: #{user_id}")
      terminate_session
      redirect_to root_path, notice: "Déconnexion réussie"
    end

    private

    # Au login d'un user non vérifié, on invalide tout code actif et on en émet un nouveau,
    # systématiquement envoyé par SMS (pattern symétrique à Vendors::SessionsController).
    # L'email reste un canal opportuniste : envoyé en plus uniquement si user.email_address.present?.
    def regenerate_verification_otp(user)
      # Invalider les éventuels codes actifs précédents
      user.user_verifications.active.update_all(expires_at: Time.current - 1.second)

      config = Rails.application.config.user_otp
      code = Otp::Generator.generate_from_config(config)
      ttl = Otp::Generator.ttl_from_config(config)

      verification = user.user_verifications.create!(
        code: code,
        channel: "sms",
        expires_at: Time.current + ttl,
        status: false
      )

      Rails.logger.info("🔢 [Client::SessionsController] OTP login généré - user_id: #{user.id}, verification_id: #{verification.id}, ttl: #{(ttl / 60).to_i}min")

      if Rails.env.development?
        puts "\n" + "=" * 70
        puts "🔑 CODE OTP CLIENT (login): #{code}"
        puts "📱 Téléphone: #{user.phone_number}"
        puts "📧 Email: #{user.email_address}" if user.email_address.present?
        puts "⏰ Valide: #{(ttl / 60).to_i} minutes"
        puts "=" * 70 + "\n"
      end

      if user.phone_number.present?
        Otp::SenderService.send_sms(user.phone_number, code, country_code: user.country_code.presence || "221")
      else
        Rails.logger.error("❌ [Client::SessionsController] User sans numéro de téléphone, impossible d'envoyer l'OTP par SMS - user_id: #{user.id}")
      end

      # Email opportuniste UNIQUEMENT si l'utilisateur a un email
      if user.email_address.present?
        Otp::SenderService.send_email(user.email_address, code)
      end
    rescue => e
      Rails.logger.error("❌ [Client::SessionsController] Erreur génération OTP login - user_id: #{user.id}, error: #{e.class} #{e.message}")
    end
  end
end
