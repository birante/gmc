# frozen_string_literal: true

module PublicLink
  extend ActiveSupport::Concern

  # Génère une URL publique pour la ressource
  # À surcharger dans les modèles si besoin d'une logique spéciale
  def public_url
    nil  # À implémenter par chaque modèle
  end

  # Alias pour accès facile
  def shareable_link
    public_url
  end
end
