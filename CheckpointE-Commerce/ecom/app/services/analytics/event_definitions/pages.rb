# frozen_string_literal: true

module Analytics
  module EventDefinitions
    # Noms de pages pour le tracking
    module Pages
      # Pages publiques
      HOME = "home"
      ABOUT = "about"
      CONTACT = "contact"
      TERMS = "terms"
      PRIVACY = "privacy"

      # Boutiques
      SHOPS_INDEX = "shops_index"
      SHOPS_SHOW = "shops_show"
      SHOPS_SEARCH = "shops_search"

      # Produits
      ITEMS_INDEX = "items_index"
      ITEMS_SHOW = "items_show"
      ITEMS_SEARCH = "items_search"

      # Panier & Checkout
      CART = "cart"
      CHECKOUT = "checkout"
      CHECKOUT_DELIVERY = "checkout_delivery"
      CHECKOUT_PAYMENT = "checkout_payment"
      CHECKOUT_CONFIRMATION = "checkout_confirmation"
      ORDER_SUCCESS = "order_success"

      # Compte utilisateur
      USER_PROFILE = "user_profile"
      USER_ORDERS = "user_orders"
      USER_ADDRESSES = "user_addresses"
      USER_FAVORITES = "user_favorites"

      # Compte vendeur
      VENDOR_DASHBOARD = "vendor_dashboard"
      VENDOR_PRODUCTS = "vendor_products"
      VENDOR_PRODUCT_NEW = "vendor_product_new"
      VENDOR_PRODUCT_EDIT = "vendor_product_edit"
      VENDOR_ORDERS = "vendor_orders"
      VENDOR_ORDER_SHOW = "vendor_order_show"
      VENDOR_SETTINGS = "vendor_settings"
      VENDOR_SHOP_EDIT = "vendor_shop_edit"
      VENDOR_ANALYTICS = "vendor_analytics"

      # Compte employé
      EMPLOYEE_DASHBOARD = "employee_dashboard"
      EMPLOYEE_PRODUCTS = "employee_products"
      EMPLOYEE_PRODUCT_NEW = "employee_product_new"
      EMPLOYEE_PRODUCT_EDIT = "employee_product_edit"
      EMPLOYEE_ORDERS = "employee_orders"
      EMPLOYEE_ORDER_SHOW = "employee_order_show"
      EMPLOYEE_ANALYTICS = "employee_analytics"

      # Authentification
      SIGN_IN = "sign_in"
      SIGN_UP = "sign_up"
      PASSWORD_RESET = "password_reset"

      # Maintenance
      MAINTENANCE = "maintenance"
      MAINTENANCE_CONFIRMATION = "maintenance_confirmation"
    end
  end
end
