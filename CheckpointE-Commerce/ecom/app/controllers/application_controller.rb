class ApplicationController < ActionController::Base
  include Authentication
  include Trackable # Analytics tracking automatique sur toutes les pages
  include RoutesHelper

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :set_locale

  # Gestion centralisée des exceptions personnalisées
  rescue_from ApplicationError, with: :handle_application_error
  rescue_from ValidationError, with: :handle_validation_error
  rescue_from NotFoundError, with: :handle_not_found_error
  rescue_from UnauthorizedError, with: :handle_unauthorized_error
  rescue_from PaymentError, with: :handle_payment_error
  rescue_from RepositoryError, with: :handle_repository_error

  # CSRF expiré (onglet laissé ouvert, Safari ITP, session perdue) : on ne renvoie pas
  # une 422 brute. On reset la session côté cookie, on préserve le panier invité,
  # et on renvoie l'utilisateur sur le formulaire d'origine avec un message clair.
  rescue_from ActionController::InvalidAuthenticityToken, with: :handle_invalid_authenticity_token

  helper_method :current_user, :current_cart, :current_cart_readonly, :user_signed_in?, :current_vendor, :vendor_signed_in?, :current_employee, :employee_signed_in?, :current_admin_user

  def current_user
    sessionable = Current.session&.sessionable
    sessionable.is_a?(User) ? sessionable : nil
  end

  def current_employee
    sessionable = Current.session&.sessionable
    sessionable.is_a?(Employee) ? sessionable : nil
  end

  def current_vendor
    sessionable = Current.session&.sessionable
    sessionable.is_a?(Vendor) ? sessionable : nil
  end

  def employee_signed_in?
    current_employee.present?
  end

  def vendor_signed_in?
    current_vendor.present?
  end

  # Récupère le panier courant ou le crée si nécessaire
  def current_cart
    @current_cart ||= begin
      if current_user
        # Utilisateur connecté : utiliser son panier
        cart = current_user.current_cart

        # Fusionner le panier invité s'il existe
        merge_guest_cart_if_needed(cart)

        cart
      else
        # Invité : utiliser un panier en session (le crée si besoin)
        find_or_create_guest_cart
      end
    end
  end

  # Récupère le panier existant SANS le créer (pour l'affichage navbar)
  def current_cart_readonly
    return @current_cart if defined?(@current_cart)

    cart_includes = {
      cart_items: [
        :item_variant,
        { item: [ :currency, :variants, { main_image_attachment: :blob }, { images_attachments: :blob } ] }
      ]
    }

    @current_cart_readonly ||= if current_user
      current_user.carts.active.includes(cart_includes).first
    else
      cart_id = session[:guest_cart_id]
      cart_id ? Cart.includes(cart_includes).find_by(id: cart_id, user_id: nil, status: "active") : nil
    end
  end

  private

  def set_locale
    I18n.locale = params[:locale] || session[:locale] || I18n.default_locale
    session[:locale] = I18n.locale
  end

  def default_url_options
    options = { locale: I18n.locale }
    # In test environment, use configured host if request not available
    if Rails.env.test? && !respond_to?(:request)
      options.merge!(Rails.application.config.action_controller.default_url_options || {})
    end
    options
  end

  def find_or_create_guest_cart
    return @guest_cart if defined?(@guest_cart)

    cart_id = session[:guest_cart_id]

    @guest_cart = if cart_id
      Cart.find_by(id: cart_id, user_id: nil, status: "active")
    end

    # Créer un nouveau panier invité seulement si nécessaire
    unless @guest_cart
      @guest_cart = Cart.create!(status: "active")
      session[:guest_cart_id] = @guest_cart.id
    end

    @guest_cart
  end

  def merge_guest_cart_if_needed(user_cart)
    guest_cart_id = session[:guest_cart_id]
    return unless guest_cart_id

    guest_cart = Cart.find_by(id: guest_cart_id, user_id: nil, status: "active")
    return unless guest_cart

    # Fusionner les articles du panier invité dans le panier utilisateur
    guest_cart.cart_items.each do |guest_item|
      existing_item = user_cart.cart_items.find_by(
        item_id: guest_item.item_id,
        item_variant_id: guest_item.item_variant_id
      )

      if existing_item
        # Ajouter les quantités si l'article existe déjà
        new_quantity = existing_item.quantity + guest_item.quantity
        # Vérifier le stock
        if new_quantity <= guest_item.variant.stock_quantity
          existing_item.update(quantity: new_quantity)
        else
          # Prendre le maximum possible
          existing_item.update(quantity: guest_item.variant.stock_quantity)
        end
      else
        # Ajouter le nouvel article
        user_cart.cart_items.create!(
          item: guest_item.item,
          item_variant: guest_item.item_variant,
          quantity: guest_item.quantity,
          unit_price: guest_item.unit_price,
          total_price: guest_item.total_price
        )
      end
    end

    # Supprimer le panier invité
    guest_cart.destroy
    session.delete(:guest_cart_id)
  end

  def user_signed_in?
    current_user.present?
  end

  def current_admin_user
    return nil unless session[:admin_user_id].present?
    @current_admin_user ||= AdminUser.find_by(id: session[:admin_user_id])
  end

  def authenticate_admin_user!
    return if current_admin_user.present?
    redirect_to new_admin_user_session_path, alert: t("active_admin.devise.unauthorized", default: "Vous devez vous connecter pour accéder à l'administration.")
  end

  # Handlers pour les exceptions personnalisées

  def handle_application_error(exception)
    exception.log(request: request.path, params: params.to_unsafe_h.except(:controller, :action))

    respond_to do |format|
      format.html do
        flash[:alert] = exception.message
        redirect_back(fallback_location: root_path)
      end
      format.json do
        render json: { error: exception.message, code: exception.code }, status: http_status_for(exception.status)
      end
    end
  end

  def handle_validation_error(exception)
    exception.log(request: request.path)

    respond_to do |format|
      format.html do
        flash.now[:alert] = exception.message
        @errors = exception.error_messages
        render :new, status: :unprocessable_entity
      end
      format.json do
        render json: { error: exception.message, errors: exception.error_messages, code: exception.code }, status: :unprocessable_entity
      end
    end
  end

  def handle_not_found_error(exception)
    exception.log(request: request.path)

    respond_to do |format|
      format.html do
        flash[:alert] = exception.message
        redirect_to root_path, status: :not_found
      end
      format.json do
        render json: { error: exception.message, code: exception.code }, status: :not_found
      end
    end
  end

  def handle_unauthorized_error(exception)
    exception.log(request: request.path, user: current_user&.id)

    respond_to do |format|
      format.html do
        flash[:alert] = exception.message
        redirect_to root_path, status: :forbidden
      end
      format.json do
        render json: { error: exception.message, code: exception.code }, status: :forbidden
      end
    end
  end

  def handle_payment_error(exception)
    exception.log(request: request.path, provider: exception.provider)

    respond_to do |format|
      format.html do
        flash[:alert] = exception.message
        redirect_back(fallback_location: root_path)
      end
      format.json do
        render json: { error: exception.message, provider: exception.provider, code: exception.code }, status: :payment_required
      end
    end
  end

  def handle_repository_error(exception)
    exception.log(request: request.path, model: exception.model&.class&.name)

    respond_to do |format|
      format.html do
        flash[:alert] = "Une erreur technique est survenue. Veuillez réessayer plus tard."
        redirect_back(fallback_location: root_path)
      end
      format.json do
        render json: { error: "Erreur technique", code: exception.code }, status: :internal_server_error
      end
    end
  end

  def handle_invalid_authenticity_token(exception)
    Rails.logger.warn("⚠️ [CSRF] Token invalide - path: #{request.path}, ip: #{request.remote_ip}, ua: #{request.user_agent}")

    # Préserver le panier invité (lié à un id en base) avant de reset la session.
    preserved_guest_cart_id = session[:guest_cart_id]
    preserved_locale = session[:locale]
    reset_session
    session[:guest_cart_id] = preserved_guest_cart_id if preserved_guest_cart_id
    session[:locale] = preserved_locale if preserved_locale

    message = "Votre session a expiré, veuillez réessayer."

    respond_to do |format|
      format.html do
        # Renvoyer vers le formulaire d'origine si on peut, sinon l'accueil.
        fallback = root_path
        target = if request.referer.present? && safe_internal_url?(request.referer)
          request.referer
        else
          fallback
        end
        redirect_to target, alert: message
      end
      format.json do
        render json: { error: message, code: "csrf_token_expired" }, status: :unprocessable_entity
      end
      format.any do
        redirect_to root_path, alert: message
      end
    end
  end

  # Vrai si l'URL pointe vers le même host (anti open-redirect).
  def safe_internal_url?(url)
    return false if url.blank?
    uri = URI.parse(url)
    uri.host.nil? || uri.host == request.host
  rescue URI::InvalidURIError
    false
  end

  # Convertit un symbole de statut en code HTTP Rails
  def http_status_for(status)
    case status
    when :bad_request then :bad_request
    when :unauthorized then :unauthorized
    when :forbidden then :forbidden
    when :not_found then :not_found
    when :unprocessable_entity then :unprocessable_entity
    when :payment_required then :payment_required
    when :internal_server_error then :internal_server_error
    else :internal_server_error
    end
  end
end
