# frozen_string_literal: true

# Repository pour les opérations sur les boutiques (Shop)
#
# Usage:
#   repo = ShopRepository.new
#   shop = repo.find_with_associations(shop_id)
#   shop = repo.create_for_vendor(vendor, attributes)
class ShopRepository < BaseRepository
  def model_class
    Shop
  end

  # Trouver une boutique avec toutes ses associations
  #
  # @param id [String, Integer] L'identifiant de la boutique
  # @return [Shop, nil] La boutique avec ses associations préchargées
  def find_with_associations(id)
    find(id, includes: [
      :vendor,
      :currency,
      :legal_info,
      :contacts,
      :social_links,
      :sectors,
      :payment_methods,
      :items,
      :employees
    ])
  end

  # Trouver une boutique par slug avec ses associations
  #
  # @param slug [String] Le slug de la boutique
  # @return [Shop, nil] La boutique avec ses associations préchargées
  def find_by_slug_with_associations(slug)
    scope = model_class.friendly
    scope.includes(
      :vendor,
      :currency,
      :legal_info,
      :contacts,
      { social_links: :social_platform },
      :sectors,
      :payment_methods
    ).find_by(slug: slug)
  rescue ActiveRecord::RecordNotFound
    nil
  end

  # Créer une boutique pour un vendor
  #
  # @param vendor [Vendor] Le vendor propriétaire de la boutique
  # @param attributes [Hash] Attributs pour créer la boutique
  # @return [Shop] La boutique créée (peut être invalide)
  def create_for_vendor(vendor, attributes)
    vendor.shops.build(attributes)
  end

  # Trouver les boutiques d'un vendor
  #
  # @param vendor [Vendor] Le vendor
  # @param options [Hash] Options de filtrage (status, limit, etc.)
  # @return [ActiveRecord::Relation] Les boutiques du vendor
  def for_vendor(vendor, options = {})
    shops = vendor.shops.all

    shops = shops.where(status: options[:status]) if options[:status].present?
    shops = shops.limit(options[:limit]) if options[:limit].present?
    shops.order(created_at: :desc)
  end

  # Trouver les boutiques actives d'un vendor
  #
  # @param vendor [Vendor] Le vendor
  # @return [ActiveRecord::Relation] Les boutiques actives
  def active_for_vendor(vendor)
    vendor.shops.active
          .includes(:currency, :legal_info, :contacts, { social_links: :social_platform }, :sectors)
          .order(created_at: :desc)
  end

  # Trouver les boutiques d'un employee
  #
  # @param employee [Employee] L'employee
  # @return [ActiveRecord::Relation] Les boutiques de l'employee
  def for_employee(employee)
    employee.shops.includes(
      :vendor,
      :currency,
      :legal_info,
      :contacts
    ).order(created_at: :desc)
  end

  # Activer une boutique
  #
  # @param shop [Shop] La boutique à activer
  # @return [Boolean] True si l'activation a réussi
  def activate(shop)
    update(shop, status: "active")
  end

  # Suspendre une boutique
  #
  # @param shop [Shop] La boutique à suspendre
  # @return [Boolean] True si la suspension a réussi
  def suspend(shop)
    update(shop, status: "suspended")
  end

  # Désactiver une boutique
  #
  # @param shop [Shop] La boutique à désactiver
  # @return [Boolean] True si la désactivation a réussi
  def deactivate(shop)
    update(shop, status: "deactivate")
  end

  # Compter les items de toutes les boutiques d'un vendor
  #
  # @param vendor [Vendor] Le vendor
  # @return [Integer] Le nombre total d'items
  def count_items_for_vendor(vendor)
    vendor.shops.joins(:items).count
  end
end
