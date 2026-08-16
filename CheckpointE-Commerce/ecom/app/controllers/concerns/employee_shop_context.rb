module EmployeeShopContext
  extend ActiveSupport::Concern

  included do
    before_action :set_current_shop_context, if: :employee_context?
  end

  private

  def employee_context?
    current_employee.present?
  end

  def set_current_shop_context
    # Déterminer le vendor via l'employé
    @vendor = current_employee&.vendor

    # Boutiques disponibles pour l'employé (uniquement ses boutiques assignées)
    available_shops = current_employee.shops.order(created_at: :desc)

    # Utiliser le service objet pour gérer le contexte de boutique
    @shop_context_service = Vendors::ShopContextService.new(
      @vendor,
      params: params,
      session: session,
      available_shops: available_shops
    )

    # Définir les boutiques
    @shops = @shop_context_service.shops

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
