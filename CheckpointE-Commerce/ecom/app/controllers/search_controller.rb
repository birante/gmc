# frozen_string_literal: true

class SearchController < ApplicationController
  allow_unauthenticated_access

  PRODUCT_LIMIT  = 6
  SHOP_LIMIT     = 3
  CATEGORY_LIMIT = 4
  MIN_QUERY_LEN  = 2

  # GET /:locale/search/suggestions(.json)
  def suggestions
    query = params[:q].to_s.strip

    if query.length < MIN_QUERY_LEN
      return render json: empty_payload(query)
    end

    render json: {
      query: query,
      products: serialize_products(search_products(query)),
      shops: serialize_shops(search_shops(query)),
      categories: serialize_categories(search_categories(query))
    }
  end

  private

  def search_products(query)
    Item.search_fuzzy(query)
        .available_for_sale
        .includes(:shop, :currency, main_image_attachment: :blob, variants: [])
        .limit(PRODUCT_LIMIT)
  end

  def search_shops(query)
    Shop.search_fuzzy(query)
        .where(status: :active)
        .includes(logo_attachment: :blob)
        .limit(SHOP_LIMIT)
  end

  def search_categories(query)
    base = ProductSubCategory.where(is_active: true)
    base.where("LOWER(name) LIKE ?", "%#{query.downcase}%").limit(CATEGORY_LIMIT)
  end

  def serialize_products(items)
    items.map do |item|
      {
        id: item.id,
        name: item.name,
        slug: item.slug,
        url: localized_item_url(item),
        image_url: item_image_url(item),
        price: item.current_price,
        currency_symbol: item.currency&.symbol,
        shop_name: item.shop&.name
      }
    end
  end

  def serialize_shops(shops)
    shops.map do |shop|
      {
        id: shop.id,
        name: shop.name,
        slug: shop.slug,
        url: localized_shop_url(shop),
        logo_url: shop_logo_url(shop)
      }
    end
  end

  def serialize_categories(categories)
    categories.map do |cat|
      {
        id: cat.id,
        name: cat.name,
        slug: cat.slug,
        url: category_sub_category_path(cat.product_category.slug, cat.slug)
      }
    end
  end

  def empty_payload(query)
    { query: query, products: [], shops: [], categories: [] }
  end

  def localized_item_url(item)
    I18n.locale.to_s == "en" ? product_path(item.slug) : produit_path(item.slug)
  end

  def localized_shop_url(shop)
    I18n.locale.to_s == "en" ? shop_path(shop.slug) : boutique_path(shop.slug)
  end

  def item_image_url(item)
    return nil unless item.main_image.attached?
    url_for(item.main_image.variant(resize_to_fill: [ 80, 80 ], format: :webp))
  rescue StandardError
    nil
  end

  def shop_logo_url(shop)
    return nil unless shop.logo.attached?
    url_for(shop.logo.variant(resize_to_fill: [ 80, 80 ], format: :webp))
  rescue StandardError
    nil
  end
end
