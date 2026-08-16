# frozen_string_literal: true

module SeoHelper
  # Schema.org Organization
  def organization_schema
    {
      "@context": "https://schema.org",
      "@type": "Organization",
      "name": "aa",
      "url": safe_root_url,
      "logo": asset_url("logo.svg"),
      "description": t("seo.organization_description", default: "Marketplace e-commerce au Sénégal"),
      "address": {
        "@type": "PostalAddress",
        "streetAddress": "Quartier Ouakam, Mamelles, Lot numéro 752, Cité El Hadj Malick SY",
        "addressLocality": "Dakar",
        "addressCountry": "SN"
      },
      "contactPoint": {
        "@type": "ContactPoint",
        "telephone": "+221-77-881-83-83",
        "contactType": "customer service",
        "areaServed": "SN",
        "availableLanguage": %w[French English Wolof]
      },
      "sameAs": [
        "https://facebook.com/aa",
        "https://instagram.com/aa",
        "https://twitter.com/aa"
      ]
    }
  end

  # Schema.org WebSite avec SearchAction
  def website_schema
    {
      "@context": "https://schema.org",
      "@type": "WebSite",
      "name": "aa",
      "url": safe_root_url,
      "potentialAction": {
        "@type": "SearchAction",
        "target": {
          "@type": "EntryPoint",
          "urlTemplate": "#{items_url}?search={search_term_string}"
        },
        "query-input": "required name=search_term_string"
      }
    }
  end

  # Schema.org pour un produit (version de base)
  def product_schema(item, variant = nil)
    variant ||= item.variants.first
    currency_code = item.currency&.code || "XOF"

    schema = {
      "@context": "https://schema.org",
      "@type": "Product",
      "name": item.name,
      "description": item.description.presence || item.name,
      "sku": variant&.sku,
      "brand": {
        "@type": "Brand",
        "name": item.shop&.name || "aa"
      },
      "offers": {
        "@type": "Offer",
        "url": item_url(item),
        "priceCurrency": currency_code,
        "price": variant&.price || 0,
        "availability": variant&.stock_quantity.to_i.positive? ? "https://schema.org/InStock" : "https://schema.org/OutOfStock",
        "itemCondition": "https://schema.org/NewCondition",
        "seller": {
          "@type": "Organization",
          "name": item.shop&.name || "aa"
        }
      }
    }

    # Ajouter l'image si disponible
    schema[:image] = item_image_url(item) if item_has_image?(item)

    schema
  end

  # Schema.org Product amélioré avec AggregateRating et Review (placeholders)
  def product_schema_enhanced(item, variant = nil)
    variant ||= item.default_variant || item.variants.first
    currency_code = item.currency&.code || "XOF"

    schema = {
      "@context": "https://schema.org",
      "@type": "Product",
      "name": item.name,
      "description": item.description.presence || item.name,
      "sku": variant&.sku,
      "brand": {
        "@type": "Brand",
        "name": item.shop&.name || "aa"
      },
      "offers": {
        "@type": "Offer",
        "url": item_url(item),
        "priceCurrency": currency_code,
        "price": variant&.price || 0,
        "availability": variant&.stock_quantity.to_i.positive? ? "https://schema.org/InStock" : "https://schema.org/OutOfStock",
        "itemCondition": "https://schema.org/NewCondition",
        "seller": {
          "@type": "Organization",
          "name": item.shop&.name || "aa"
        }
      }
    }

    # Ajouter l'image si disponible
    schema[:image] = item_image_url(item) if item_has_image?(item)

    # Ajouter la catégorie si disponible
    if item.product_sub_category
      schema[:category] = item.product_sub_category.name
    end

    # AggregateRating à partir des avis approuvés (rich snippet ⭐ dans Google).
    approved_reviews = item.reviews.approved if item.respond_to?(:reviews)
    if item.average_rating.present? && approved_reviews&.any?
      schema[:aggregateRating] = {
        "@type": "AggregateRating",
        "ratingValue": item.average_rating.to_f.round(2),
        "reviewCount": approved_reviews.size,
        "bestRating": "5",
        "worstRating": "1"
      }

      # Joindre jusqu'à 5 avis pour enrichir le rich snippet.
      schema[:review] = approved_reviews.order(created_at: :desc).limit(5).map do |review|
        {
          "@type": "Review",
          "author": { "@type": "Person", "name": review.user&.first_name.to_s.presence || "Anonyme" },
          "datePublished": review.created_at.iso8601,
          "reviewBody": review.comment.to_s,
          "reviewRating": {
            "@type": "Rating",
            "ratingValue": review.rating,
            "bestRating": "5",
            "worstRating": "1"
          }
        }
      end
    end

    schema
  end

  # Schema.org pour une liste de produits (Collection)
  def item_list_schema(items, list_name)
    {
      "@context": "https://schema.org",
      "@type": "ItemList",
      "name": list_name,
      "numberOfItems": items.size,
      "itemListElement": items.each_with_index.map do |item, index|
        {
          "@type": "ListItem",
          "position": index + 1,
          "item": {
            "@type": "Product",
            "name": item.name,
            "url": item_url(item)
          }
        }
      end
    }
  end

  # Schema.org CollectionPage pour une page de catégorie
  def collection_page_schema(category, items)
    items_count = items.respond_to?(:total_count) ? items.total_count : items.count

    {
      "@context": "https://schema.org",
      "@type": "CollectionPage",
      "name": category.name,
      "description": category.description.presence || "Produits de la catégorie #{category.name}",
      "url": category_url(category),
      "mainEntity": {
        "@type": "ItemList",
        "url": category_url(category),
        "numberOfItems": items_count,
        "itemListElement": items.limit(20).each_with_index.map do |item, index|
          variant = item.default_variant || item.variants.first
          {
            "@type": "ListItem",
            "position": index + 1,
            "item": {
              "@type": "Product",
              "name": item.name,
              "url": item_url(item),
              "image": item_image_url(item),
              "offers": {
                "@type": "Offer",
                "url": item_url(item),
                "price": variant&.price || 0,
                "priceCurrency": item.currency&.code || "XOF",
                "availability": variant&.stock_quantity.to_i.positive? ? "https://schema.org/InStock" : "https://schema.org/OutOfStock",
                "itemCondition": "https://schema.org/NewCondition",
                "seller": {
                  "@type": "Organization",
                  "name": item.shop&.name || "aa"
                }
              }
            }
          }
        end
      }
    }
  end

  # Schema.org Category pour une catégorie
  def category_schema(category)
    {
      "@context": "https://schema.org",
      "@type": "Category",
      "name": category.name,
      "description": category.description,
      "url": category_url(category)
    }
  end

  # Schema.org BreadcrumbList
  def breadcrumb_schema(crumbs)
    {
      "@context": "https://schema.org",
      "@type": "BreadcrumbList",
      "itemListElement": crumbs.each_with_index.map do |(name, url), index|
        {
          "@type": "ListItem",
          "position": index + 1,
          "name": name,
          "item": url
        }
      end
    }
  end

  # Schema.org WebPage + BreadcrumbList pour la page d'accueil (e-commerce)
  def homepage_webpage_schema
    root = safe_root_url
    {
      "@context": "https://schema.org",
      "@type": %w[WebPage CollectionPage],
      "@id": "#{root}#webpage",
      "url": root,
      "name": t("seo.home.title"),
      "description": t("seo.home.description"),
      "inLanguage": I18n.locale.to_s,
      "isPartOf": {
        "@type": "WebSite",
        "name": "aa",
        "url": root
      },
      "breadcrumb": { "@id": "#{root}#breadcrumb" }
    }
  end

  # Schema.org BreadcrumbList pour la page d'accueil (un seul élément)
  def homepage_breadcrumb_schema
    root = safe_root_url
    {
      "@context": "https://schema.org",
      "@type": "BreadcrumbList",
      "@id": "#{root}#breadcrumb",
      "itemListElement": [
        {
          "@type": "ListItem",
          "position": 1,
          "name": t("breadcrumbs.home", default: "Accueil"),
          "item": root
        }
      ]
    }
  end

  # Schema.org WebPage générique (AboutPage / ContactPage / WebPage selon type).
  # Utilisé pour les pages éditoriales (à propos, contact, conditions, blog index)
  # qui n'ont pas de schéma plus spécifique.
  def simple_page_schema(name:, description:, url:, type: "WebPage")
    {
      "@context": "https://schema.org",
      "@type": type,
      "name": name,
      "description": description,
      "url": url,
      "inLanguage": I18n.locale.to_s,
      "isPartOf": {
        "@type": "WebSite",
        "name": "aa",
        "url": safe_root_url
      },
      "publisher": {
        "@type": "Organization",
        "name": "aa",
        "logo": {
          "@type": "ImageObject",
          "url": asset_url("logo.svg")
        }
      }
    }
  end

  # Schema.org BlogPosting pour un article de blog (rich snippet "Article" dans Google).
  def blog_posting_schema(post)
    schema = {
      "@context": "https://schema.org",
      "@type": "BlogPosting",
      "headline": post.title,
      "description": post.excerpt.presence || post.content.to_plain_text.truncate(160),
      "datePublished": (post.published_at || post.created_at).iso8601,
      "dateModified": post.updated_at.iso8601,
      "author": {
        "@type": "Person",
        "name": post.author_name.presence || "Équipe aa"
      },
      "publisher": {
        "@type": "Organization",
        "name": "aa",
        "logo": {
          "@type": "ImageObject",
          "url": asset_url("logo.svg")
        }
      },
      "mainEntityOfPage": {
        "@type": "WebPage",
        "@id": blog_post_url(post)
      },
      "inLanguage": I18n.locale.to_s
    }

    if post.cover_image.attached?
      image_url = url_for(post.cover_image.variable? ? post.cover_image.variant(resize_to_limit: [ 1200, 800 ]) : post.cover_image)
      schema[:image] = absolutize_url(image_url)
    end

    if post.blog_category
      schema[:articleSection] = post.blog_category.name
    end

    schema
  end

  # Schema.org BreadcrumbList pour un article de blog.
  # Accueil → Blog → [Catégorie si présente] → Article
  def blog_breadcrumb_schema(post)
    crumbs = [
      [ t("breadcrumbs.home", default: "Accueil"), safe_root_url ],
      [ t("pages.blog.nav_label", default: "Blog"), blog_url ]
    ]

    if post.blog_category
      crumbs << [ post.blog_category.name, blog_category_url(post.blog_category.slug) ]
    end

    crumbs << [ post.title, blog_post_url(post) ]

    breadcrumb_schema(crumbs)
  end

  # Schema.org LocalBusiness pour une boutique
  def shop_schema(shop)
    {
      "@context": "https://schema.org",
      "@type": "LocalBusiness",
      "name": shop.name,
      "description": shop.description.presence || "Boutique #{shop.name} sur aa",
      "url": shop_url(shop),
      "address": {
        "@type": "PostalAddress",
        "streetAddress": shop.address,
        "addressLocality": "Dakar",
        "addressCountry": "SN"
      },
      "parentOrganization": {
        "@type": "Organization",
        "name": "aa",
        "url": safe_root_url
      }
    }
  end

  # Lit une valeur SEO éditable depuis l'admin (SiteSetting), avec fallback sur la
  # traduction I18n correspondante. Permet aux admins de modifier titre/description
  # de la home (et d'autres pages clés) sans déploiement.
  def site_seo(key, fallback_i18n_key: nil, **i18n_options)
    value = SiteSetting.get(key)
    return value if value.present?

    fallback_key = fallback_i18n_key || key
    t(fallback_key, **i18n_options)
  end

  # Helper pour générer le JSON-LD dans les vues
  def json_ld_tag(schema)
    content_tag(:script, raw(schema.to_json), type: "application/ld+json")
  end

  # Helper pour combiner plusieurs schemas
  def combined_json_ld_tag(*schemas)
    content_tag(:script, raw(schemas.to_json), type: "application/ld+json")
  end

  private

  def safe_root_url
    if respond_to?(:default_url_options)
      root_url(default_url_options)
    else
      root_url
    end
  rescue ActionController::UrlGenerationError
    # Fallback for test environment
    "http://example.com"
  end

  # Préfixe une URL relative (`/rails/...`) avec le scheme+host courant.
  # Utile pour les URLs ActiveStorage dans les schemas JSON-LD (Google
  # exige des URLs absolues).
  def absolutize_url(url)
    return url if url.blank? || url.match?(%r{\Ahttps?://})

    uri = URI.parse(safe_root_url)
    "#{uri.scheme}://#{uri.host}#{":#{uri.port}" if uri.port && ![ 80, 443 ].include?(uri.port)}#{url}"
  rescue URI::InvalidURIError
    url
  end

  def item_has_image?(item)
    item.respond_to?(:main_image) && item.main_image.attached?
  end

  def item_image_url(item)
    if item_has_image?(item)
      url_for(item.main_image)
    else
      asset_url("empty-product.svg")
    end
  rescue StandardError
    asset_url("empty-product.svg")
  end
end
