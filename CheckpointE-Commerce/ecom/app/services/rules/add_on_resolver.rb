# frozen_string_literal: true

module Rules
  # Service de résolution des add-ons actifs pour une boutique
  #
  # Usage:
  #   resolver = Rules::AddOnResolver.new(shop)
  #   extra_days = resolver.extra_meta_days
  class AddOnResolver
    def initialize(shop)
      @shop = shop
    end

    # Retourne le nombre de jours Meta supplémentaires (add-on actif)
    # @return [Integer] Nombre de jours supplémentaires (0 si non actif)
    def extra_meta_days
      addon = find_active_addon("EXTRA_META_DAYS")
      addon&.quantity.to_i
    end

    # Vérifie si la livraison express est activée
    # @return [Boolean]
    def express_delivery?
      find_active_addon("EXPRESS_DELIVERY").present?
    end

    # Vérifie si Analytics Pro est activé
    # @return [Boolean]
    def analytics_pro?
      find_active_addon("ANALYTICS_PRO").present?
    end

    # Vérifie si le design premium est activé
    # @return [Boolean]
    def storefront_premium?
      find_active_addon("STORE_FRONT_PREMIUM").present?
    end

    # Retourne tous les add-ons actifs pour cette boutique
    # @return [Array<ShopAddOn>]
    def active_add_ons
      shop.shop_add_ons.active.includes(:add_on)
    end

    private

    attr_reader :shop

    # Trouve un add-on actif par son code
    def find_active_addon(code)
      shop.shop_add_ons
          .active
          .joins(:add_on)
          .find_by(add_ons: { code: code, is_active: true })
    end
  end
end
