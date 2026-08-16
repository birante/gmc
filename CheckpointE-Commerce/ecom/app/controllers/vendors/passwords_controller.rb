module Vendors
  class PasswordsController < ApplicationController
    allow_unauthenticated_access

    layout "vendor_onboarding", only: [ :new, :create, :edit, :update ]

    def new
    end

    def create
      vendor = Vendor.find_by(email: params[:email])

      if vendor && vendor.email.present?
        # Générer un token de réinitialisation
        token = generate_reset_token(vendor)
        begin
          # Utiliser deliver_later pour ne pas bloquer la requête HTTP
          # L'email sera envoyé en arrière-plan via SolidQueue
          Vendors::PasswordsMailer.reset(vendor, token).deliver_later
          Rails.logger.info "🔑 [Vendors::PasswordsController] Email reset password envoyé - vendor_id: #{vendor.id}, email: #{vendor.email}"

          # TODO: Envoyer SMS avec le lien de réinitialisation
          # Si le vendeur a un numéro de téléphone, envoyer aussi un SMS:
          # if vendor.phone_number.present?
          #   reset_url = edit_vendors_password_url(token)
          #   message = "Réinitialisation de mot de passe: #{reset_url} (valide 1h). Si vous n'avez pas demandé ce lien, ignorez ce message."
          #   Sms::SmsService.new.send_sms(
          #     to: vendor.formatted_phone_number,
          #     message: message,
          #     sms_type: "verification"
          #   )
          # rescue Sms::SmsService::SmsDisabledError => e
          #   Rails.logger.info("SMS désactivé, notification non envoyée")
          # rescue StandardError => e
          #   Rails.logger.error("Erreur envoi SMS reset password: #{e.message}")
          # end

          # En développement avec letter_opener, informer l'utilisateur
          if Rails.env.development? && ActionMailer::Base.delivery_method == :letter_opener
            redirect_to new_vendors_session_path, notice: "Email envoyé ! Vérifiez la fenêtre qui s'est ouverte dans votre navigateur (letter_opener) ou consultez tmp/letter_opener/"
          else
            redirect_to new_vendors_session_path, notice: "Instructions de réinitialisation envoyées à votre adresse email (#{vendor.email})."
          end
        rescue => e
          Rails.logger.error "❌ [Vendors::PasswordsController] Échec envoi email reset: #{e.class} - #{e.message}\n#{e.backtrace.first(5).join("\n")}"
          redirect_to new_vendors_session_path, alert: "Erreur lors de l'envoi de l'email: #{e.message}. Veuillez réessayer."
          nil
        end
      else
        # Ne pas révéler si l'email existe ou non pour des raisons de sécurité
        redirect_to new_vendors_session_path, notice: "Si cette adresse email existe, vous recevrez les instructions de réinitialisation."
      end
    end

    def edit
      @vendor = find_vendor_by_token(params[:token])
      unless @vendor
        redirect_to new_vendors_password_path, alert: "Le lien de réinitialisation est invalide ou a expiré."
      end
    end

    def update
      @vendor = find_vendor_by_token(params[:token])

      unless @vendor
        redirect_to new_vendors_password_path, alert: "Le lien de réinitialisation est invalide ou a expiré."
        return
      end

      if @vendor.update(password_params)
        Rails.logger.info("✅ [Vendors::PasswordsController] Mot de passe réinitialisé - vendor_id: #{@vendor.id}")
        # Terminer toute session client existante
        if Current.session
          Current.session.destroy
          cookies.delete(:session_id)
        end

        session[:vendor_id] = @vendor.id
        redirect_to vendors_dashboard_path, notice: "Mot de passe réinitialisé avec succès. Vous êtes maintenant connecté."
      else
        flash.now[:alert] = @vendor.errors.full_messages.join(", ")
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def password_params
      params.require(:vendor).permit(:password, :password_confirmation)
    end

    def generate_reset_token(vendor)
      # Utiliser un token sécurisé basé sur le timestamp et l'ID
      verifier = ActiveSupport::MessageVerifier.new(Rails.application.secret_key_base)
      verifier.generate("#{vendor.id}-#{Time.current.to_i}")
    end

    def find_vendor_by_token(token)
      verifier = ActiveSupport::MessageVerifier.new(Rails.application.secret_key_base)
      data = verifier.verify(token)
      vendor_id, timestamp = data.split("-")

      # Token valide pendant 15 minutes
      if Time.current.to_i - timestamp.to_i > 15.minutes
        return nil
      end

      Vendor.find_by(id: vendor_id)
    rescue ActiveSupport::MessageVerifier::InvalidSignature, ArgumentError
      nil
    end
  end
end
