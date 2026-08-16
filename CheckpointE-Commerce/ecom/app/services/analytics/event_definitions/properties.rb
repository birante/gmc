# frozen_string_literal: true

module Analytics
  module EventDefinitions
    # Propriétés standards pour le tracking
    module Properties
      # Propriétés communes
      PAGE_NAME = :page_name
      PAGE_URL = :page_url
      PAGE_REFERRER = :page_referrer

      # Boutique
      SHOP_ID = :shop_id
      SHOP_NAME = :shop_name
      SHOP_SLUG = :shop_slug
      VENDOR_ID = :vendor_id

      # Produit
      ITEM_ID = :item_id
      ITEM_NAME = :item_name
      ITEM_PRICE = :item_price
      ITEM_CATEGORY = :item_category
      ITEM_SUB_CATEGORY = :item_sub_category
      ITEM_SKU = :item_sku

      # Commande
      ORDER_ID = :order_id
      ORDER_NUMBER = :order_number
      ORDER_TOTAL = :order_total
      ORDER_ITEMS_COUNT = :order_items_count

      # Panier
      CART_TOTAL = :cart_total
      CART_ITEMS_COUNT = :cart_items_count
      QUANTITY = :quantity

      # Utilisateur
      USER_ID = :user_id
      USER_TYPE = :user_type
      USER_EMAIL = :user_email

      # Source & Attribution
      SOURCE = :source
      MEDIUM = :medium
      CAMPAIGN = :campaign
      UTM_SOURCE = :utm_source
      UTM_MEDIUM = :utm_medium
      UTM_CAMPAIGN = :utm_campaign

      # Contexte
      LOCALE = :locale
      CURRENCY = :currency
      TIMESTAMP = :timestamp
    end
  end
end
