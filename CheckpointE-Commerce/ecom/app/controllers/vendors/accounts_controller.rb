module Vendors
  class AccountsController < BaseController
    SESSION_KEY = :vendors_account_pending
    OTP_TTL = 10.minutes

    def show
      @vendor = current_vendor
    end

    def edit
      @vendor = current_vendor
    end

    def update
      @vendor = current_vendor
      permitted = account_params

      # Retirer le mot de passe s'il est vide (utilisateur ne veut pas changer)
      if permitted[:password].blank?
        permitted = permitted.except(:password, :password_confirmation)
      end

      # Détecter changements sensibles (email, phone) → OTP requis
      sensitive_changes = extract_sensitive_changes(permitted)
      safe_attrs = permitted.except(:email, :phone_number, :country_code)

      # Vérifier unicité du nouveau contact avant d'engager le flux OTP
      if sensitive_changes.key?(:email) && email_taken?(sensitive_changes[:email])
        @vendor.errors.add(:email, "est déjà utilisé par un autre compte")
        return render :edit, status: :unprocessable_entity
      end

      if sensitive_changes.key?(:phone)
        new_phone = sensitive_changes[:phone][:phone_number]
        new_cc = sensitive_changes[:phone][:country_code]
        if phone_taken?(new_phone)
          @vendor.errors.add(:phone_number, "est déjà utilisé par un autre compte")
          return render :edit, status: :unprocessable_entity
        end
        unless PhoneValidationService.valid?(new_phone, new_cc)
          @vendor.errors.add(:phone_number, "n'est pas valide pour le pays sélectionné")
          return render :edit, status: :unprocessable_entity
        end
      end

      # Appliquer les changements non sensibles d'abord
      unless @vendor.update(safe_attrs)
        return render :edit, status: :unprocessable_entity
      end

      if sensitive_changes.any?
        initiate_change_flow(sensitive_changes)
        redirect_to confirm_change_vendors_account_path,
                    notice: "Un code de vérification vous a été envoyé pour confirmer le changement."
      else
        redirect_to vendors_account_path, notice: "Vos informations ont été mises à jour avec succès."
      end
    end

    def confirm_change
      pending = session[SESSION_KEY]
      if pending.blank?
        redirect_to vendors_account_path and return
      end

      if request.patch?
        submitted = extract_submitted_code
        if code_expired?(pending)
          flash.now[:alert] = "Le code a expiré. Demandez un nouveau code."
          @pending = pending
          return render :confirm_change, status: :unprocessable_entity
        end

        unless ActiveSupport::SecurityUtils.secure_compare(submitted.to_s, pending["code"].to_s)
          flash.now[:alert] = "Code invalide."
          @pending = pending
          return render :confirm_change, status: :unprocessable_entity
        end

        apply_target_change!(pending)
        remaining = pending["changes"].except(pending["target"])

        if remaining.any?
          next_target = remaining.keys.first
          new_pending = pending.merge("changes" => remaining, "target" => next_target)
          new_pending = regenerate_code(new_pending)
          send_code(new_pending)
          session[SESSION_KEY] = new_pending
          redirect_to confirm_change_vendors_account_path,
                      notice: "Changement confirmé. Un nouveau code a été envoyé pour la prochaine modification."
        else
          session.delete(SESSION_KEY)
          redirect_to vendors_account_path, notice: "Vos informations ont été mises à jour avec succès."
        end
      else
        @pending = pending
      end
    end

    def resend_change_code
      pending = session[SESSION_KEY]
      redirect_to vendors_account_path and return if pending.blank?

      new_pending = regenerate_code(pending)
      send_code(new_pending)
      session[SESSION_KEY] = new_pending
      redirect_to confirm_change_vendors_account_path, notice: "Un nouveau code vous a été envoyé."
    end

    private

    def account_params
      params.require(:vendor).permit(
        :first_name,
        :last_name,
        :email,
        :phone_number,
        :country_code,
        :password,
        :password_confirmation
      )
    end

    def extract_sensitive_changes(permitted)
      changes = {}

      if permitted[:email].present?
        new_email = permitted[:email].to_s.strip.downcase
        changes[:email] = new_email if new_email != @vendor.email.to_s.downcase
      end

      new_phone = permitted[:phone_number].to_s.strip.gsub(/\D/, "")
      new_cc = permitted[:country_code].to_s.strip
      phone_changed = new_phone.present? && new_phone != @vendor.phone_number.to_s
      cc_changed = new_cc.present? && new_cc != @vendor.country_code.to_s
      if phone_changed || cc_changed
        changes[:phone] = {
          phone_number: new_phone.presence || @vendor.phone_number.to_s,
          country_code: new_cc.presence || @vendor.country_code.to_s
        }
      end

      changes
    end

    def email_taken?(email)
      Vendor.where("LOWER(email) = ?", email.downcase).where.not(id: @vendor.id).exists?
    end

    def phone_taken?(phone)
      Vendor.where(phone_number: phone).where.not(id: @vendor.id).exists?
    end

    def initiate_change_flow(changes)
      target = changes.key?(:email) ? "email" : "phone"
      code = Otp::Generator.generate(length: 4)
      pending = {
        "changes" => changes.deep_stringify_keys,
        "target" => target,
        "code" => code,
        "expires_at" => (Time.current + OTP_TTL).iso8601
      }
      send_code(pending)
      session[SESSION_KEY] = pending
    end

    def regenerate_code(pending)
      pending.merge(
        "code" => Otp::Generator.generate(length: 4),
        "expires_at" => (Time.current + OTP_TTL).iso8601
      )
    end

    def send_code(pending)
      case pending["target"]
      when "email"
        Otp::SenderService.send_email(pending.dig("changes", "email"), pending["code"])
      when "phone"
        phone = pending.dig("changes", "phone")
        Otp::SenderService.send_sms(phone["phone_number"], pending["code"], country_code: phone["country_code"])
      end
    end

    def apply_target_change!(pending)
      case pending["target"]
      when "email"
        @vendor.update!(email: pending.dig("changes", "email"))
      when "phone"
        phone = pending.dig("changes", "phone")
        @vendor.update!(phone_number: phone["phone_number"], country_code: phone["country_code"])
      end
    end

    def code_expired?(pending)
      return true if pending["expires_at"].blank?
      Time.iso8601(pending["expires_at"]) < Time.current
    rescue ArgumentError
      true
    end

    def extract_submitted_code
      # Support saisie 4 champs (otp_code_0..3) ou champ unique otp_code
      digits = [ params[:otp_code_0], params[:otp_code_1], params[:otp_code_2], params[:otp_code_3] ]
      combined = digits.compact.map(&:to_s).join
      combined.presence || params[:otp_code].to_s.strip
    end
  end
end
