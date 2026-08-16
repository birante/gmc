# frozen_string_literal: true

module VendorsHelper
  include PlansHelper

  # Helper pour ajouter automatiquement le shop_slug à une URL
  # Accepte des paramètres supplémentaires optionnels
  def url_with_shop(path, shop, **options)
    # Convertir le path en string
    path_str = path.to_s

    # Construire les paramètres de requête
    params = {}
    params[:shop_slug] = shop.slug if shop && shop.slug.present?
    params.merge!(options) if options.any?

    # Si aucun paramètre, retourner le path tel quel
    return path_str if params.empty?

    # Construire l'URL avec les paramètres
    query_string = params.map { |k, v| "#{k}=#{CGI.escape(v.to_s)}" }.join("&")
    separator = path_str.include?("?") ? "&" : "?"
    "#{path_str}#{separator}#{query_string}"
  end

  # Helper pour générer le bon chemin selon le contexte (employé ou vendeur)
  def order_path_for_context(order, **options)
    if current_employee
      employees_order_path(order, **options)
    else
      vendors_order_path(order, **options)
    end
  end

  # Helper pour générer le bon chemin d'update de statut
  # NOTE: update_status n'existe plus pour les vendors (supprimé intentionnellement)
  # Les vendeurs ne peuvent plus modifier manuellement le statut de la commande
  def update_status_order_path_for_context(order)
    if current_employee
      update_status_employees_order_path(order)
    else
      # Les vendors ne peuvent plus modifier le statut de la commande
      # Seuls les order_items peuvent être mis à jour via update_item_delivery_status
      nil
    end
  end

  # Helper pour générer le bon chemin d'update de statut de livraison
  def update_item_delivery_status_order_path_for_context(order)
    if current_employee
      update_item_delivery_status_employees_order_path(order)
    else
      update_item_delivery_status_vendors_order_path(order)
    end
  end

  # Helper pour obtenir les IDs des boutiques selon le contexte
  def shop_ids_for_context
    if current_employee
      current_employee.shops.pluck(:id)
    elsif @vendor
      @vendor.shops.pluck(:id)
    else
      []
    end
  end

  # Helper pour filtrer les order_items selon le contexte
  def order_items_scope_for_context(order)
    if current_employee
      # Pour les employés : filtrer par leurs boutiques assignées
      if @current_shop
        # Si une boutique est active, filtrer uniquement par cette boutique
        order.order_items.joins(:shop).where(shops: { id: @current_shop.id })
      else
        # Sinon, filtrer par toutes leurs boutiques assignées
        order.order_items.joins(:shop).where(shops: { id: current_employee.shops.pluck(:id) })
      end
    elsif @vendor
      # Pour les vendeurs : filtrer par la boutique active ou toutes leurs boutiques
      if @current_shop
        # Si une boutique est active, filtrer uniquement par cette boutique
        order.order_items.joins(:shop).where(shops: { id: @current_shop.id })
      elsif @shop_condition && @shop_value
        # Utiliser les conditions de filtrage définies par le contexte
        order.order_items.joins(:shop).where(@shop_condition, @shop_value)
      else
        # Fallback : filtrer par toutes leurs boutiques
        order.order_items.joins(:shop).where(shops: { vendor_id: @vendor.id })
      end
    else
      order.order_items.none
    end
  end

  # =========================================================================
  # HELPERS POUR LES CAPABILITIES (RÈGLES & LIMITES)
  # =========================================================================

  # Vérifie si la boutique peut créer un produit
  def can_create_product?(shop)
    return false unless shop
    shop.capabilities.can_create_product?(shop.items_count)
  end

  # Vérifie si la boutique peut ajouter un employé
  def can_add_employee?(shop)
    return false unless shop
    shop.capabilities.can_add_employee?(shop.employees.active.count)
  end

  # Retourne la limite de produits (nil = illimité)
  def max_products_for(shop)
    return nil unless shop
    shop.capabilities.max_products
  end

  # Retourne la limite d'employés (nil = illimité)
  def max_employees_for(shop)
    return nil unless shop
    shop.capabilities.max_employees
  end

  # Formate l'affichage de la limite (avec "illimité" si nil)
  def format_limit(max, current)
    return I18n.t("services.rules.unlimited") if max.nil?
    "#{current} / #{max}"
  end

  # Vérifie si les multi-utilisateurs sont activés
  def multi_users_enabled?(shop)
    return false unless shop
    shop.capabilities.multi_users?
  end

  # Vérifie si les analytics sont activés
  def analytics_enabled?(shop)
    return false unless shop
    shop.capabilities.analytics_enabled?
  end

  # Calcule le pourcentage d'utilisation d'une limite
  def usage_percentage(current, max)
    max_i = max.to_i
    return 0 if max_i.zero?
    [ (current.to_f / max_i * 100), 100 ].min
  end

  # Détermine si on approche de la limite (>= 80%)
  def near_limit?(current, max)
    return false if max.nil?
    usage_percentage(current, max) >= 80
  end

  # Détermine si la limite est atteinte (>= 95%)
  def limit_reached?(current, max)
    return false if max.nil?
    usage_percentage(current, max) >= 95
  end

  # Retourne les plans disponibles qui ont une fonctionnalité spécifique
  def available_plans_with_feature(shop, feature_code)
    return [] unless shop

    current_plan = shop.current_subscription&.plan
    plans_scope = Plan.active.standard
                      .includes(plan_rules: :rule)
                      .where.not(id: current_plan&.id)

    # 1) Cas nominal : fonctionnalité portée par une règle active
    feature_rule = Rule.find_by(code: feature_code, is_active: true)
    if feature_rule
      return plans_scope.select do |plan|
        plan_rule = plan.plan_rules.find { |pr| pr.rule_id == feature_rule.id && pr.is_active }
        next false unless plan_rule

        case feature_rule.code
        when "max_employees"
          plan_rule.value.to_i > 1
        when "max_products"
          plan_rule.value.present? && plan_rule.value.to_i.positive?
        else
          ActiveModel::Type::Boolean.new.cast(plan_rule.value)
        end
      end
    end

    # 2) Compatibilité : fonctionnalités dérivées (ex: multi_users, order_management, aa_delivery)
    #    calculées via plan_features sans dépendre d'une règle DB supprimée.
    feature_key = feature_code.to_s
    plans_scope.select { |plan| plan_features(plan)[feature_key.to_sym] }
  end
end
