module EmployeesHelper
  # Helper pour ajouter automatiquement le shop_id à une URL
  # Accepte des paramètres supplémentaires optionnels
  def url_with_shop(path, shop, **options)
    # Convertir le path en string
    path_str = path.to_s

    # Construire les paramètres de requête
    params = {}
    params[:shop_id] = shop.id if shop && shop.id.present?
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
  def update_status_order_path_for_context(order)
    if current_employee
      update_status_employees_order_path(order)
    else
      update_status_vendors_order_path(order)
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
      order.order_items.joins(:shop).where(shops: { id: current_employee.shops.pluck(:id) })
    elsif @vendor
      # Pour les vendeurs : filtrer par toutes leurs boutiques
      order.order_items.joins(:shop).where(shops: { vendor_id: @vendor.id })
    else
      order.order_items.none
    end
  end
end
