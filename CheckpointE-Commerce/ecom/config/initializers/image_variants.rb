# frozen_string_literal: true

# Configuration des variantes d'images pour Active Storage
# Utilise MiniMagick pour le traitement des images

Rails.application.config.active_storage.variant_processor = :mini_magick

# Définir les variantes d'images standard pour le e-commerce
Rails.application.config.after_initialize do
  # Module pour les variantes d'images produits
  module ImageVariants
    VARIANTS = {
      # Vignette pour les listes et grilles compactes
      thumbnail: {
        resize_to_fill: [ 200, 200 ],
        format: :webp
      },
      # Carte produit pour les grilles standard
      card: {
        resize_to_fill: [ 400, 400 ],
        format: :webp
      },
      # Image détail pour la page produit
      detail: {
        resize_to_limit: [ 800, 800 ],
        format: :webp
      },
      # Image hero pour les bannières
      hero: {
        resize_to_limit: [ 1280, 600 ],
        format: :webp
      },
      # Image de galerie (zoom)
      gallery: {
        resize_to_limit: [ 1200, 1200 ],
        format: :webp
      }
    }.freeze

    # Variantes pour les logos et bannières de boutiques
    SHOP_VARIANTS = {
      logo_small: {
        resize_to_fill: [ 100, 100 ],
        format: :webp
      },
      logo_medium: {
        resize_to_fill: [ 200, 200 ],
        format: :webp
      },
      banner: {
        resize_to_limit: [ 1280, 400 ],
        format: :webp
      }
    }.freeze
  end
end
