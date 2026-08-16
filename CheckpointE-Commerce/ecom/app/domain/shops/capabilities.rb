# frozen_string_literal: true

module Shops
  # Facade métier pour exposer les capacités d'une boutique
  # Traduit les règles techniques en langage métier lisible
  #
  # Usage:
  #   capabilities = shop.capabilities
  #   if capabilities.can_create_product?(shop.items_count)
  #     # créer le produit
  #   end
  class Capabilities
    def initialize(shop)
      @shop = shop
      @resolver = Rules::RuleResolver.new(shop)
      @addon_resolver = Rules::AddOnResolver.new(shop)
    end

    # =========================================================================
    # PRODUITS
    # =========================================================================

    # Vérifie si la boutique peut créer un nouveau produit
    # @param current_count [Integer] Nombre actuel de produits
    # @return [Boolean] true si la limite n'est pas atteinte
    def can_create_product?(current_count)
      max = @resolver.value("max_products")
      return true if max.nil? # illimité

      current_count.to_i < max.to_i
    end

    # Retourne la limite de produits (nil = illimité)
    # @return [Integer, nil]
    def max_products
      @resolver.value("max_products")
    end

    # =========================================================================
    # UTILISATEURS & EMPLOYÉS
    # =========================================================================

    # Vérifie si la boutique peut ajouter un employé
    # @param current_count [Integer] Nombre actuel d'employés
    # @return [Boolean]
    def can_add_employee?(current_count)
      max = @resolver.value("max_employees")
      return true if max.nil? # illimité

      current_count.to_i < max.to_i
    end

    # Vérifie si les multi-utilisateurs sont activés
    # Multi-users = max_employees > 1 (inclut nil = illimité)
    # @return [Boolean]
    def multi_users?
      max_emp = max_employees
      # nil (illimité) ou entier > 1 = multi-users
      max_emp.nil? || max_emp.to_i > 1
    end

    # Retourne la limite d'employés (nil = illimité)
    # @return [Integer, nil]
    def max_employees
      @resolver.value("max_employees")
    end

    # =========================================================================
    # ANALYTICS
    # =========================================================================

    # Vérifie si les analytics sont activés
    # @return [Boolean]
    def analytics_enabled?
      @resolver.enabled?("analytics_enabled")
    end

    # =========================================================================
    # OPÉRATIONS
    # =========================================================================

    # Vérifie si la gestion des commandes est activée
    # Compatibilité avec le set de règles simplifié (sans order_management)
    # @return [Boolean]
    def order_management?
      !access_plan?
    end

    # Vérifie si la livraison aa est activée
    # Compatibilité avec le set de règles simplifié (sans aa_delivery)
    # @return [Boolean]
    def aa_delivery?
      !access_plan?
    end

    # =========================================================================
    # IA - G\u00c9N\u00c9RATION DE CONTENU
    # =========================================================================

    # V\u00e9rifie si la g\u00e9n\u00e9ration de titre/description en temps r\u00e9el est activ\u00e9e
    # @return [Boolean]
    def ai_title_description_enabled?
      @resolver.enabled?("ai_title_description_enabled")
    end

    # V\u00e9rifie si la g\u00e9n\u00e9ration en arri\u00e8re-plan est activ\u00e9e
    # @return [Boolean]
    def ai_background_generation_enabled?
      @resolver.enabled?("ai_background_generation_enabled")
    end

    # V\u00e9rifie si la g\u00e9n\u00e9ration titre/description depuis photo est activ\u00e9e
    # @return [Boolean]
    def ai_photo_generation_enabled?
      @resolver.enabled?("ai_photo_generation_enabled")
    end

    # =========================================================================
    # DESIGN & CUSTOMISATION
    # =========================================================================

    # Vérifie si le design premium est activé (add-on)
    # @return [Boolean]
    def storefront_premium?
      @addon_resolver.storefront_premium?
    end

    # =========================================================================
    # ACCÈS DIRECT AU RESOLVER (pour cas avancés)
    # =========================================================================

    # Accès direct au resolver pour des cas spécifiques
    # @return [Rules::RuleResolver]
    attr_reader :resolver

    # Accès direct au resolver d'add-ons
    # @return [Rules::AddOnResolver]
    attr_reader :addon_resolver

    private

    def access_plan?
      @shop.current_subscription&.plan&.code == "ACCESS"
    end
  end
end
