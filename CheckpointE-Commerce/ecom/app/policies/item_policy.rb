# frozen_string_literal: true

# Policy pour gérer les autorisations sur les Items (produits)
# Utilise les capabilities de la boutique pour déterminer les permissions
class ItemPolicy
  def initialize(user, item)
    @user = user
    @item = item
    @shop = item.shop
  end

  # Vérifie si l'utilisateur peut créer un produit
  # @return [Boolean]
  def create?
    return false unless @shop
    return false unless @shop.active?

    # Vérifie la limite de produits via les capabilities
    @shop.capabilities.can_create_product?(@shop.items_count)
  end

  # Vérifie si l'utilisateur peut mettre à jour un produit
  # @return [Boolean]
  def update?
    return false unless @shop
    return false unless @shop.active?

    # Pour l'instant, autoriser si la boutique est active
    # Vous pouvez ajouter d'autres règles ici (ex: plan Business uniquement)
    true
  end

  # Vérifie si l'utilisateur peut supprimer un produit
  # @return [Boolean]
  def destroy?
    return false unless @shop
    return false unless @shop.active?

    # Vérifier qu'il n'y a pas de commandes en cours
    @item.order_items.empty?
  end

  private

  attr_reader :user, :item, :shop
end
