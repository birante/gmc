# frozen_string_literal: true

# Helper pour générer les bonnes URLs selon la locale
# Permet d'utiliser items_path, item_path, shops_path, shop_path
# qui génèrent automatiquement /fr/produits ou /en/products selon la locale
module RoutesHelper
  # Helper pour générer le chemin des produits selon la locale
  def items_path(*args)
    if I18n.locale == :fr
      produits_path(*args)
    else
      # Utiliser la méthode générée par Rails pour éviter la récursion
      Rails.application.routes.url_helpers.products_path(*args)
    end
  end

  # Helper pour générer l'URL complète des produits selon la locale
  def items_url(*args)
    # Extract options hash if present
    options = args.extract_options!

    # Add host configuration for URL generation
    options = ensure_host_options(options)

    args << options

    if I18n.locale == :fr
      produits_url(*args)
    else
      # Utiliser la méthode générée par Rails pour éviter la récursion
      Rails.application.routes.url_helpers.products_url(*args)
    end
  end

  # Helper pour générer le chemin d'un produit selon la locale
  def item_path(item, options = {})
    # Ensure locale is set in options
    options = options.merge(locale: I18n.locale) unless options.key?(:locale)

    if I18n.locale == :fr
      produit_path(item, options)
    else
      # Utiliser la méthode générée par Rails pour éviter la récursion
      Rails.application.routes.url_helpers.product_path(item, options)
    end
  end

  # Helper pour générer l'URL complète d'un produit selon la locale
  def item_url(item, options = {})
    # Add host configuration for URL generation
    options = ensure_host_options(options)

    if I18n.locale == :fr
      produit_url(item, options)
    else
      # Utiliser la méthode générée par Rails pour éviter la récursion
      Rails.application.routes.url_helpers.product_url(item, options)
    end
  end

  # Helper pour générer le chemin des boutiques selon la locale
  def shops_path(*args)
    if I18n.locale == :fr
      boutiques_path(*args)
    else
      # Utiliser la méthode générée par Rails pour éviter la récursion
      Rails.application.routes.url_helpers.shops_path(*args)
    end
  end

  # Helper pour générer l'URL complète des boutiques selon la locale
  def shops_url(*args)
    # Extract options hash if present
    options = args.extract_options!

    # Add host configuration for URL generation
    options = ensure_host_options(options)

    args << options

    if I18n.locale == :fr
      boutiques_url(*args)
    else
      # Utiliser la méthode générée par Rails pour éviter la récursion
      Rails.application.routes.url_helpers.shops_url(*args)
    end
  end

  # Helper pour générer le chemin d'une boutique selon la locale
  def shop_path(shop, options = {})
    # Ensure locale is set in options
    options = options.merge(locale: I18n.locale) unless options.key?(:locale)

    if I18n.locale == :fr
      boutique_path(shop, options)
    else
      # Utiliser la méthode générée par Rails pour éviter la récursion
      Rails.application.routes.url_helpers.shop_path(shop, options)
    end
  end

  # Helper pour générer l'URL complète d'une boutique selon la locale
  def shop_url(shop, options = {})
    # Add host configuration for URL generation
    options = ensure_host_options(options)

    if I18n.locale == :fr
      boutique_url(shop, options)
    else
      # Utiliser la méthode générée par Rails pour éviter la récursion
      Rails.application.routes.url_helpers.shop_url(shop, options)
    end
  end

  # Helper pour générer l'URL complète d'une catégorie (même chemin dans les deux langues)
  # Accepte soit un objet Category, soit un slug (string)
  def category_url(category_or_slug, options = {})
    slug = category_or_slug.is_a?(String) ? category_or_slug : category_or_slug.slug
    # Utiliser les helpers de routes Rails avec le host de la requête
    url_helpers = Rails.application.routes.url_helpers

    # Construire les options avec le host
    url_options = { locale: I18n.locale }.merge(options)

    # Ajouter le host depuis la requête si disponible
    if respond_to?(:request) && request.present?
      url_options[:host] = request.host
      url_options[:port] = request.port if request.port != 80 && request.port != 443
    end

    # Passer le slug comme premier argument, puis les options
    url_helpers.category_url(slug, url_options)
  end

  # Helper pour générer l'URL complète d'une sous-catégorie (même chemin dans les deux langues)
  # Accepte soit des objets Category/SubCategory, soit des slugs (strings)
  def category_sub_category_url(category_or_slug, sub_category_or_slug, options = {})
    category_slug = category_or_slug.is_a?(String) ? category_or_slug : category_or_slug.slug
    sub_category_slug = sub_category_or_slug.is_a?(String) ? sub_category_or_slug : sub_category_or_slug.slug
    # Utiliser les helpers de routes Rails avec le host de la requête
    url_helpers = Rails.application.routes.url_helpers

    # Construire les options avec le host
    url_options = { locale: I18n.locale }.merge(options)

    # Ajouter le host depuis la requête si disponible
    if respond_to?(:request) && request.present?
      url_options[:host] = request.host
      url_options[:port] = request.port if request.port != 80 && request.port != 443
    end

    # Passer les slugs comme arguments positionnels, puis les options
    url_helpers.category_sub_category_url(category_slug, sub_category_slug, url_options)
  end

  private

  # Ensure URL options have a host configured for URL generation
  def ensure_host_options(options = {})
    # Always include locale
    options[:locale] ||= I18n.locale

    return options if options[:host].present?

    # Try to get host from request if available
    if respond_to?(:request) && request.present?
      options[:host] = request.host
      options[:port] = request.port if request.port != 80 && request.port != 443
      return options
    end

    # Fall back to configured default_url_options (for tests)
    if Rails.env.test? && Rails.application.config.action_controller.default_url_options
      options.merge(Rails.application.config.action_controller.default_url_options)
    else
      options
    end
  end
end
