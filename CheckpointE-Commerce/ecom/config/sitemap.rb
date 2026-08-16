# frozen_string_literal: true

# Sitemap dynamique pour les moteurs de recherche.
# Utilise les routes publiques SEO-friendly (FR par défaut — l'EN est signalé
# via les balises hreflang dans le <head> de chaque page).
SitemapGenerator::Sitemap.default_host = ENV.fetch("SITEMAP_HOST", "https://sn.aa.com")

SitemapGenerator::Sitemap.create do
  default_locale = :fr

  # Accueil
  add root_path(locale: default_locale), priority: 1.0, changefreq: "daily"

  # Pages légales
  add terms_path(locale: default_locale), priority: 0.3, changefreq: "monthly"
  add privacy_path(locale: default_locale), priority: 0.3, changefreq: "monthly"

  # Listing boutiques (FR : /fr/boutiques)
  add boutiques_path(locale: default_locale), priority: 0.9, changefreq: "daily"
  add official_client_shops_path(locale: default_locale), priority: 0.8, changefreq: "daily"
  add local_client_shops_path(locale: default_locale), priority: 0.8, changefreq: "daily"

  # Catalogue produits (FR : /fr/produits)
  add produits_path(locale: default_locale), priority: 0.9, changefreq: "daily"

  # Catégories (FR : /fr/categories/:slug)
  ProductCategory.where(is_active: true).find_each do |category|
    add category_path(slug: category.slug, locale: default_locale),
        priority: 0.7,
        changefreq: "daily",
        lastmod: category.updated_at
  end

  # Sous-catégories (FR : /fr/categories/:cat/:sub)
  ProductSubCategory.where(is_active: true).includes(:product_category).find_each do |sub_category|
    next unless sub_category.product_category
    add category_sub_category_path(
          category_slug: sub_category.product_category.slug,
          sub_category_slug: sub_category.slug,
          locale: default_locale
        ),
        priority: 0.6,
        changefreq: "daily",
        lastmod: sub_category.updated_at
  end

  # Boutiques individuelles (FR : /fr/boutiques/:slug)
  Shop.where(status: :active).find_each do |shop|
    add boutique_path(slug: shop.slug, locale: default_locale),
        priority: 0.7,
        changefreq: "weekly",
        lastmod: shop.updated_at
  end

  # Produits individuels (FR : /fr/produits/:slug)
  Item.available_for_sale.find_each do |item|
    add produit_path(id: item.slug, locale: default_locale),
        priority: 0.5,
        changefreq: "weekly",
        lastmod: item.updated_at
  end

  # Pages éditoriales
  add about_path(locale: default_locale),   priority: 0.5, changefreq: "monthly"
  add contact_path(locale: default_locale), priority: 0.4, changefreq: "monthly"

  # Blog : index, catégories, articles publiés
  add blog_path(locale: default_locale), priority: 0.7, changefreq: "daily"

  BlogCategory.active.find_each do |category|
    add blog_category_path(slug: category.slug, locale: default_locale),
        priority: 0.6,
        changefreq: "weekly",
        lastmod: category.updated_at
  end

  BlogPost.published.find_each do |post|
    add blog_post_path(id: post.slug, locale: default_locale),
        priority: 0.6,
        changefreq: "weekly",
        lastmod: post.updated_at
  end
end
