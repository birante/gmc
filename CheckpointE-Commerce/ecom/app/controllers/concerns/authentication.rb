module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :resume_session # Toujours résumer la session, même pour les pages publiques
    before_action :require_authentication
    helper_method :authenticated?
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end
  end

  private
    def authenticated?
      resume_session
    end

    def require_authentication
      # Pages ActiveAdmin (/admin) : pas d’exigence de session client (l’auth admin est gérée par ActiveAdmin)
      return if self.class.name.start_with?("Admin::")

      # Utilisateur déjà connecté en admin (si le contrôleur a la méthode)
      return if respond_to?(:current_admin_user) && current_admin_user.present?

      resume_session || request_authentication
    end

    def resume_session
      # In test mode, Current.session may already be set by the test helper
      # In production, we need to find it from the cookie
      Current.session ||= find_test_session || find_session_by_cookie
    end

    def find_test_session
      return nil unless Rails.env.test?
      return nil unless params[:test_vendor_id].present?

      vendor = Vendor.find_by(id: params[:test_vendor_id])
      return nil unless vendor

      # Create or find a test session for this vendor
      vendor.sessions.find_or_create_by!(ip_address: "127.0.0.1") do |session|
        session.user_agent = "Test User Agent"
      end
    end

    def find_session_by_cookie
      Session.find_by(id: cookies.signed[:session_id]) if cookies.signed[:session_id]
    end

    def request_authentication
      session[:return_to_after_authenticating] = request.url

      # Déterminer la route de session selon le contexte
      session_path = case
      when self.class.name.start_with?("Employees::")
        new_employees_session_path
      when self.class.name.start_with?("Vendors::")
        new_vendors_session_path
      when self.class.name.start_with?("Client::")
        new_client_session_path
      else
        # Par défaut, rediriger vers la page client
        new_client_session_path
      end

      redirect_to session_path
    end

    def after_authentication_url
      session.delete(:return_to_after_authenticating) || root_url
    end

    def start_new_session_for(user)
      user.sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip).tap do |session|
        Current.session = session
        cookies.signed.permanent[:session_id] = { value: session.id, httponly: true, same_site: :lax }
      end
    end

    def terminate_session
      Current.session&.destroy
      cookies.delete(:session_id)
      Current.session = nil
    end

    # Valide que l'URL de redirection est sûre (même domaine ou chemin relatif)
    def safe_redirect_url?(url)
      return false if url.blank?
      return true if url.start_with?("/") && !url.start_with?("//")

      begin
        uri = URI.parse(url)
        # Autoriser uniquement les URLs relatives ou du même host
        uri.host.nil? || uri.host == request.host
      rescue URI::InvalidURIError
        false
      end
    end
end
