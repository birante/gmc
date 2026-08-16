# frozen_string_literal: true

module Analytics
  module EventDefinitions
    # Événements de tracking
    module Events
      # Pages & Navigation
      PAGE_VIEWED = "page_viewed"

      # Boutiques
      SHOP_VIEWED = "shop_viewed"
      SHOP_SEARCHED = "shop_searched"
      SHOP_FAVORITED = "shop_favorited"
      SHOP_CONTACT_CLICKED = "shop_contact_clicked"

      # Produits/Items
      ITEM_VIEWED = "item_viewed"
      ITEM_SEARCHED = "item_searched"
      ITEM_FILTERED = "item_filtered"
      ITEM_FAVORITED = "item_favorited"

      # Panier
      ITEM_ADDED_TO_CART = "item_added_to_cart"
      ITEM_REMOVED_FROM_CART = "item_removed_from_cart"
      CART_VIEWED = "cart_viewed"
      CART_CLEARED = "cart_cleared"

      # Checkout & Commandes
      CHECKOUT_STARTED = "checkout_started"
      CHECKOUT_STEP_COMPLETED = "checkout_step_completed"
      CHECKOUT_STEP_VIEWED = "checkout_step_viewed"
      ORDER_COMPLETED = "order_completed"
      ORDER_CANCELLED = "order_cancelled"

      # Paiement
      PAYMENT_METHOD_SELECTED = "payment_method_selected"
      PAYMENT_INITIATED = "payment_initiated"
      PAYMENT_SUCCEEDED = "payment_succeeded"
      PAYMENT_FAILED = "payment_failed"

      # Livraison
      DELIVERY_ZONE_SELECTED = "delivery_zone_selected"
      DELIVERY_SLOT_SELECTED = "delivery_slot_selected"
      DELIVERY_ADDRESS_ADDED = "delivery_address_added"

      # Authentification
      USER_SIGNED_UP = "user_signed_up"
      USER_SIGNED_IN = "user_signed_in"
      USER_SIGNED_OUT = "user_signed_out"
      VENDOR_SIGNED_UP = "vendor_signed_up"
      VENDOR_SIGNED_IN = "vendor_signed_in"
      VENDOR_SIGNED_OUT = "vendor_signed_out"
      EMPLOYEE_SIGNED_IN = "employee_signed_in"
      EMPLOYEE_SIGNED_OUT = "employee_signed_out"

      # Actions Vendeur
      VENDOR_SHOP_CREATED = "vendor_shop_created"
      VENDOR_PRODUCT_CREATED = "vendor_product_created"
      VENDOR_PRODUCT_UPDATED = "vendor_product_updated"
      VENDOR_PRODUCT_DELETED = "vendor_product_deleted"
      VENDOR_ORDER_VIEWED = "vendor_order_viewed"
      VENDOR_ORDER_PROCESSED = "vendor_order_processed"
      VENDOR_DASHBOARD_VIEWED = "vendor_dashboard_viewed"

      # Actions Employé
      EMPLOYEE_SHOP_ACCESSED = "employee_shop_accessed"
      EMPLOYEE_ORDER_MANAGED = "employee_order_managed"
      EMPLOYEE_PRODUCT_MANAGED = "employee_product_managed"

      # Actions Client
      CLIENT_PROFILE_UPDATED = "client_profile_updated"
      CLIENT_ADDRESS_ADDED = "client_address_added"
      CLIENT_ORDER_TRACKED = "client_order_tracked"

      # Engagement
      NEWSLETTER_SUBSCRIBED = "newsletter_subscribed"
      SOCIAL_LINK_CLICKED = "social_link_clicked"
      REVIEW_SUBMITTED = "review_submitted"

      # Erreurs & Performance
      ERROR_OCCURRED = "error_occurred"
      PAGE_LOAD_SLOW = "page_load_slow"
    end
  end
end
