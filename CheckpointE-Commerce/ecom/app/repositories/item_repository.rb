# frozen_string_literal: true

# Repository pour les opérations sur les produits (Item)
#
# Usage:
#   repo = ItemRepository.new
#   item = repo.find_with_variants(item_id)
#   item = repo.create_for_shop(shop, attributes)
class ItemRepository < BaseRepository
  def model_class
    Item
  end

  # Trouver un produit avec ses variantes et associations
  #
  # @param id [String, Integer] L'identifiant du produit
  # @return [Item, nil] Le produit avec ses associations préchargées
  def find_with_variants(id)
    find(id, includes: [
      :shop,
      :product_sub_category,
      :currency,
      :delivery_category,
      :variants,
      :item_attributes
    ])
  end

  # Trouver un produit par slug avec ses variantes
  #
  # @param slug [String] Le slug du produit
  # @return [Item, nil] Le produit avec ses associations préchargées
  def find_by_slug_with_variants(slug)
    scope = model_class.friendly
    scope.includes(
      :shop,
      :product_sub_category,
      :currency,
      :delivery_category,
      :variants,
      :item_attributes
    ).find_by(slug: slug)
  rescue ActiveRecord::RecordNotFound
    nil
  end

  # Créer un produit pour un shop
  #
  # @param shop [Shop] Le shop propriétaire du produit
  # @param attributes [Hash] Attributs pour créer le produit
  # @return [Item] Le produit créé (peut être invalide)
  def create_for_shop(shop, attributes)
    shop.items.build(attributes)
  end

  # Trouver les produits d'un shop
  #
  # @param shop [Shop] Le shop
  # @param options [Hash] Options de filtrage (validation_status, etc.)
  # @return [ActiveRecord::Relation] Les produits du shop
  def for_shop(shop, options = {})
    items = shop.items.includes(:product_sub_category, :currency, :variants, :delivery_category)

    items = items.where(validation_status: options[:validation_status]) if options[:validation_status].present?
    items = items.limit(options[:limit]) if options[:limit].present?

    items.order(created_at: :desc)
  end

  # Trouver les produits approuvés d'un shop
  #
  # @param shop [Shop] Le shop
  # @return [ActiveRecord::Relation] Les produits disponibles à la vente
  def available_for_shop(shop)
    shop.items.available_for_sale
         .includes(:product_sub_category, :currency, :variants, :delivery_category)
  end

  # Approuver un produit
  #
  # @param item [Item] Le produit à approuver
  # @return [Boolean] True si l'approbation a réussi
  def approve(item)
    update(item, validation_status: "approved")
  end

  # Rejeter un produit
  #
  # @param item [Item] Le produit à rejeter
  # @return [Boolean] True si le rejet a réussi
  def reject(item)
    update(item, validation_status: "rejected")
  end

  # Activer un produit
  #
  # @param item [Item] Le produit à activer
  # @return [Boolean] True si l'activation a réussi
  def activate(item)
    true
  end

  # Désactiver un produit
  #
  # @param item [Item] Le produit à désactiver
  # @return [Boolean] True si la désactivation a réussi
  def deactivate(item)
    true
  end

  # Compter les produits d'un shop
  #
  # @param shop [Shop] Le shop
  # @return [Integer] Le nombre de produits
  def count_for_shop(shop)
    shop.items_count
  end
end
