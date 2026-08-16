# frozen_string_literal: true

module ImageOptimizationHelper
  # Image optimisée avec lazy loading et attributs de performance
  # @param source [String] chemin de l'image
  # @param alt [String] texte alternatif (requis pour l'accessibilité)
  # @param options [Hash] options supplémentaires
  # @option options [Boolean] :eager charger immédiatement (pour LCP)
  # @option options [Boolean] :priority ajouter fetchpriority="high"
  # @option options [Boolean] :disable_lazy désactiver le lazy loading (utile pour carrousels)
  # @option options [Integer] :width largeur de l'image
  # @option options [Integer] :height hauteur de l'image
  # @option options [String] :class classes CSS
  def optimized_image_tag(source, alt:, **options)
    # Extraire les options personnalisées
    eager = options.delete(:eager) || false
    priority = options.delete(:priority) || false
    disable_lazy = options.delete(:disable_lazy) || false

    # Extraire et convertir l'option aria si présente
    aria_options = options.delete(:aria)
    if aria_options.is_a?(Hash)
      aria_options.each do |key, value|
        options["aria-#{key}".to_sym] = value
      end
    end

    # Construire les attributs par défaut
    defaults = {
      alt: alt,
      loading: (eager || disable_lazy) ? "eager" : "lazy",
      decoding: "async"
    }

    # Ajouter fetchpriority pour les images critiques (LCP)
    defaults[:fetchpriority] = "high" if priority

    # Ajouter les dimensions si fournies (évite le CLS)
    defaults[:width] = options.delete(:width) if options[:width]
    defaults[:height] = options.delete(:height) if options[:height]

    # Fusionner avec les options utilisateur
    image_tag(source, **defaults.merge(options))
  end

  # Picture element avec support WebP et fallback
  # @param source [String] chemin de l'image source (jpg, png)
  # @param alt [String] texte alternatif
  # @param options [Hash] options pour l'image
  def picture_with_webp(source, alt:, **options)
    webp_source = source.to_s.sub(/\.(jpe?g|png)$/i, ".webp")

    content_tag(:picture) do
      safe_join([
        tag(:source, type: "image/webp", srcset: asset_path(webp_source)),
        optimized_image_tag(source, alt: alt, **options)
      ])
    end
  rescue StandardError
    # Fallback si pas de WebP disponible
    optimized_image_tag(source, alt: alt, **options)
  end

  # Image Active Storage optimisée avec variantes
  # @param attachment [ActiveStorage::Attached] l'attachment Active Storage
  # @param variant_name [Symbol] nom de la variante (:thumbnail, :card, :detail, :hero)
  # @param alt [String] texte alternatif
  # @param options [Hash] options supplémentaires
  # @option options [Boolean] :eager charger immédiatement (pour LCP)
  # @option options [Boolean] :priority ajouter fetchpriority="high"
  # @option options [Integer] :width largeur de l'image
  # @option options [Integer] :height hauteur de l'image
  def storage_image_tag(attachment, variant_name: :card, alt:, **options)
    storage_source = normalize_storage_image_source(attachment)
    return image_placeholder(variant: variant_name, **options) unless storage_source

    # Extraire les dimensions par défaut selon la variante
    default_dimensions = case variant_name
    when :thumbnail then { width: 200, height: 200 }
    when :card then { width: 400, height: 400 }
    when :detail then { width: 800, height: 800 }
    when :hero then { width: 1024, height: 480 }
    when :logo_small then { width: 100, height: 100 }
    when :logo_medium then { width: 200, height: 200 }
    when :banner then { width: 1024, height: 320 }
    when :icon then { width: 100, height: 100 }
    else {}
    end

    # Utiliser les dimensions passées en options si fournies, sinon utiliser les dimensions par défaut
    width = options.delete(:width) || default_dimensions[:width]
    height = options.delete(:height) || default_dimensions[:height]

    begin
      # Qualité WebP : 60 pour les images de fond/hero/banner (perte
      # imperceptible, gain de poids 50-70%) ; 75 pour les produits/cards où
      # la lisibilité du détail compte ; 80 pour la vue détaillée.
      # NB : la clé `quality` est passée en top-level (compatible mini_magick),
      # pas via `saver:` qui est réservé au backend `vips`.
      variant = case variant_name
      when :thumbnail then storage_source.variant(resize_to_fill: [ 200, 200 ], format: :webp, quality: 70)
      when :card then storage_source.variant(resize_to_fill: [ 400, 400 ], format: :webp, quality: 75)
      when :detail then storage_source.variant(resize_to_limit: [ 800, 800 ], format: :webp, quality: 80)
      when :hero then storage_source.variant(resize_to_limit: [ 1024, 480 ], format: :webp, quality: 60)
      when :logo_small then storage_source.variant(resize_to_fill: [ 100, 100 ], format: :webp, quality: 80)
      when :logo_medium then storage_source.variant(resize_to_fill: [ 200, 200 ], format: :webp, quality: 80)
      when :banner then storage_source.variant(resize_to_limit: [ 1024, 320 ], format: :webp, quality: 60)
      when :icon then storage_source.variant(resize_to_fill: [ 100, 100 ], format: :webp, quality: 80)
      else storage_source
      end

      # Ajouter les dimensions pour éviter le CLS (Cumulative Layout Shift)
      optimized_options = options.dup
      optimized_options[:width] = width if width
      optimized_options[:height] = height if height

      optimized_image_tag(url_for(variant), alt: alt, **optimized_options)
    rescue StandardError => e
      # Fallback : utiliser l'image originale si la variante échoue
      Rails.logger.warn("⚠️ [ImageOptimizationHelper] Impossible de générer la variante #{variant_name}: #{e.message}")
      optimized_options = options.dup
      optimized_options[:width] = width if width
      optimized_options[:height] = height if height
      optimized_image_tag(url_for(storage_source), alt: alt, **optimized_options)
    end
  end

  # Renvoie une variante WebP d'un attachment Active Storage, ou l'image
  # d'origine si ce n'est pas un attachment (URL CDN, asset statique, etc.).
  # À utiliser pour les hero/banner/promo qui ne passent pas par
  # `storage_image_tag` (cas où on garde la main sur le markup `<img>`).
  #
  # @param image [ActiveStorage::Attached::One, ActiveStorage::Blob, String, nil]
  # @param max_width [Integer]
  # @param max_height [Integer]
  # @param quality [Integer] (60-80, défaut 65)
  def webp_variant(image, max_width:, max_height:, quality: 65)
    return image if image.blank?
    return image unless image.respond_to?(:variant)
    image.variant(resize_to_limit: [ max_width, max_height ], format: :webp, quality: quality)
  rescue StandardError => e
    Rails.logger.warn("[ImageOptimizationHelper] webp_variant fallback: #{e.message}")
    image
  end

  def normalize_storage_image_source(source)
    return nil if source.blank?

    if source.is_a?(ActiveStorage::Attachment)
      source.blob
    elsif source.respond_to?(:attached?)
      source.attached? ? source : nil
    else
      source
    end
  end

  # Placeholder pour les images manquantes
  # Utilise une image SVG selon le contexte (product, banner, logo, etc.)
  # @param options [Hash] options
  # @option options [Symbol] :variant :product, :banner, :logo, :icon, :card, :thumbnail (default: :card)
  # @option options [String] :aspect_ratio ratio d'aspect CSS (fallback si pas d'image)
  # @option options [String] :class classes CSS additionnelles
  def image_placeholder(variant: :card, aspect_ratio: nil, **options)
    css_class = options.delete(:class) || ""
    placeholder_path = placeholder_path_for_variant(variant)

    if placeholder_path && asset_exists?(placeholder_path)
      content_tag(:div, class: "overflow-hidden rounded-[10px] #{css_class}".strip, style: aspect_ratio ? "aspect-ratio: #{aspect_ratio}" : nil) do
        image_tag(placeholder_path, alt: "", role: "img", "aria-hidden": "true", class: "w-full h-full object-cover")
      end
    else
      # Fallback SVG inline (style Tendances du moment)
      ratio = aspect_ratio || "1/1"
      content_tag(:div, class: "bg-[#e3e3ec] rounded-[10px] overflow-hidden flex items-center justify-center #{css_class}".strip, style: "aspect-ratio: #{ratio}") do
        content_tag(:div, class: "w-full h-full bg-gradient-to-br from-gray-100 to-gray-200 flex items-center justify-center", "aria-hidden": "true") do
          content_tag(:svg, class: "w-8 h-8 text-gray-300", fill: "none", stroke: "currentColor", viewBox: "0 0 24 24") do
            tag(:path,
                "stroke-linecap": "round",
                "stroke-linejoin": "round",
                "stroke-width": "1",
                d: "M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z")
          end
        end
      end
    end
  end

  # Chemin du placeholder selon le variant
  # :card et :thumbnail utilisent le fallback inline (style Tendances du moment - fond gris + icône)
  def placeholder_path_for_variant(variant)
    case variant.to_sym
    when :thumbnail, :card, :detail then nil # Style inline Tendances du moment
    when :hero, :banner then "placeholders/placeholder-banner.svg"
    when :logo_small, :logo_medium, :icon then "placeholders/placeholder-logo.svg"
    else nil
    end
  end

  def asset_exists?(path)
    return false unless path.present?
    # Propshaft (Rails 8) n'a pas find_asset ; Sprockets l'a
    if Rails.application.respond_to?(:assets) && Rails.application.assets.respond_to?(:find_asset)
      Rails.application.assets.find_asset(path).present?
    else
      base = Rails.root.join("app", "assets", "images")
      path_parts = path.to_s.split("/")
      (base.join(*path_parts)).exist?
    end
  end

  # Image avec srcset responsive pour différentes tailles d'écran
  # @param source [String] chemin de l'image
  # @param alt [String] texte alternatif
  # @param sizes [String] attribut sizes pour le responsive
  # @param options [Hash] options supplémentaires
  def responsive_image_tag(source, alt:, sizes: nil, **options)
    default_sizes = "(max-width: 640px) 100vw, (max-width: 1024px) 50vw, 33vw"

    optimized_image_tag(
      source,
      alt: alt,
      sizes: sizes || default_sizes,
      **options
    )
  end
end
