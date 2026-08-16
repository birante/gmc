# frozen_string_literal: true

# Repository pour les opérations sur les paniers (Cart)
#
# Usage:
#   repo = CartRepository.new
#   cart = repo.find_active(id)
#   cart = repo.create(attributes)
class CartRepository < BaseRepository
  def model_class
    Cart
  end

  # Trouver un panier actif
  #
  # @param id [Integer] L'identifiant du panier
  # @return [Cart, nil] Le panier actif ou nil
  def find_active(id)
    find_by(id: id, status: "active")
  end

  # Trouver le panier actif d'un utilisateur
  #
  # @param user [User] L'utilisateur
  # @return [Cart, nil] Le panier actif de l'utilisateur
  def current_for_user(user)
    user.carts.find_by(status: "active")
  end

  # Trouver ou créer un panier actif pour un utilisateur
  #
  # @param user [User] L'utilisateur (peut être nil pour panier invité)
  # @return [Cart] Le panier actif (nouveau ou existant)
  def find_or_create_for_user(user = nil)
    return create!(status: "active") unless user

    user.current_cart || create!(user: user, status: "active")
  end

  # Marquer un panier comme complété
  #
  # @param cart [Cart] Le panier à compléter
  # @return [Boolean] True si la mise à jour a réussi
  def complete(cart)
    update(cart, status: "completed")
  end

  # Marquer un panier comme complété avec !
  #
  # @param cart [Cart] Le panier à compléter
  # @return [Cart] Le panier complété
  def complete!(cart)
    update!(cart, status: "completed")
  end
end
