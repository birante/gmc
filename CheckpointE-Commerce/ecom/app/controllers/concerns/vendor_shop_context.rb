module VendorShopContext
  extend ActiveSupport::Concern

  included do
    before_action :set_current_shop_context, if: :vendor_context?
  end

  private

  # Le concern tourne dès qu'on est connecté en tant que vendor OU en tant que
  # collaborateur de ce vendor : un collaborateur autorisé peut naviguer sur les
  # pages vendor (cf. Vendors::BaseController#authenticate_vendor_or_employee).
  def vendor_context?
    current_vendor.present? || current_employee.present?
  end

  def set_current_shop_context
    # Le vendor « actif » : soit le vendor connecté, soit le vendor du collaborateur
    @vendor = current_vendor || current_employee&.vendor
    return unless @vendor

    # Boutiques visibles : toutes celles du vendor pour un vendor connecté,
    # uniquement les boutiques assignées pour un collaborateur.
    available_shops = if current_employee
                        current_employee.shops.order(created_at: :desc)
    else
                        @vendor.shops.order(created_at: :desc)
    end

    # Utiliser le service objet pour gérer le contexte de boutique
    @shop_context_service = Vendors::ShopContextService.new(
      @vendor,
      params: params,
      session: session,
      available_shops: available_shops
    )

    # Ne définir @shops que s'il n'est pas déjà défini (pour permettre aux actions de le surcharger avec des includes)
    @shops ||= @shop_context_service.shops

    # Déterminer la boutique active via le service
    @current_shop = @shop_context_service.current_shop

    # Sauvegarder dans la session via le service
    @shop_context_service.update_session

    # Pour compatibilité avec les vues existantes
    @shop = @current_shop

    # Variables pour le filtrage SQL (utilisées dans les contrôleurs)
    @shop_condition = @shop_context_service.shop_condition_sql
    @shop_value = @shop_context_service.shop_condition_value
  end
end
