# frozen_string_literal: true

# Repository pour les opérations sur les commandes (Order)
#
# Usage:
#   repo = OrderRepository.new
#   order = repo.find_with_items(order_id)
#   order = repo.create_for_user(user, attributes)
class OrderRepository < BaseRepository
  def model_class
    Order
  end

  # Trouver une commande avec ses order_items et associations
  #
  # @param id [String, Integer] L'identifiant de la commande
  # @return [Order, nil] La commande avec ses associations préchargées
  def find_with_items(id)
    find(id, includes: [
      :user,
      :currency,
      :delivery_zone,
      :delivery_slot,
      order_items: [ :item, :shop ]
    ])
  end

  # Trouver une commande par slug avec ses order_items
  #
  # @param slug [String] Le slug de la commande
  # @return [Order, nil] La commande avec ses associations préchargées
  def find_by_slug_with_items(slug)
    scope = model_class.friendly
    scope.includes(:user, :currency, :delivery_zone, :delivery_slot, order_items: [ :item, :shop ])
         .find_by(slug: slug)
  rescue ActiveRecord::RecordNotFound
    nil
  end

  # Construire une commande pour un utilisateur (non sauvegardée)
  #
  # @param user [User] L'utilisateur propriétaire de la commande
  # @param attributes [Hash] Attributs pour construire la commande
  # @return [Order] La commande non sauvegardée
  def build_for_user(user, attributes)
    user.orders.new(attributes)
  end

  # Créer une commande pour un utilisateur
  #
  # @param user [User] L'utilisateur propriétaire de la commande
  # @param attributes [Hash] Attributs pour créer la commande
  # @return [Order] La commande créée
  def create_for_user(user, attributes)
    user.orders.create(attributes)
  end

  # Trouver les commandes d'un utilisateur
  #
  # @param user [User] L'utilisateur
  # @param options [Hash] Options de filtrage (status, limit, etc.)
  # @return [ActiveRecord::Relation] Les commandes de l'utilisateur
  def for_user(user, options = {})
    orders = user.orders.includes(:currency, :delivery_zone, order_items: [ :item, :shop ])
    orders = orders.where(status: options[:status]) if options[:status].present?
    orders = orders.limit(options[:limit]) if options[:limit].present?
    orders.order(created_at: :desc)
  end

  # Trouver les commandes d'un shop via order_items
  #
  # @param shop_id [Integer] L'identifiant du shop
  # @param options [Hash] Options de filtrage
  # @return [ActiveRecord::Relation] Les commandes du shop
  def for_shop(shop_id, options = {})
    orders = model_class.joins(:order_items)
                       .where(order_items: { shop_id: shop_id })
                       .includes(:user, :currency, order_items: [ :item, :shop ])
                       .distinct

    orders = orders.where(status: options[:status]) if options[:status].present?
    orders = orders.limit(options[:limit]) if options[:limit].present?
    orders.order(created_at: :desc)
  end
end
