# frozen_string_literal: true

# Charger tous les modules d'événements
require_relative "event_definitions/events"
require_relative "event_definitions/pages"
require_relative "event_definitions/properties"
require_relative "event_definitions/categories"

module Analytics
  module EventDefinitions
    # ==========================================
    # HELPER METHODS
    # ==========================================

    # Valider qu'un événement existe
    def self.valid_event?(event_name)
      Events.constants.map { |c| Events.const_get(c) }.include?(event_name)
    end

    # Obtenir tous les événements
    def self.all_events
      Events.constants.map { |c| Events.const_get(c) }
    end

    # Obtenir toutes les pages
    def self.all_pages
      Pages.constants.map { |c| Pages.const_get(c) }
    end

    # Rendre un nom de page lisible pour l'affichage (avec I18n)
    def self.humanize_page_name(page_name, locale: I18n.locale)
      return I18n.t("analytics.page_names.unknown", locale: locale, default: "Page sans nom") if page_name.blank?

      I18n.t(
        "analytics.page_names.#{page_name}",
        locale: locale,
        default: page_name.titleize
      )
    end

    # Mapper controller#action vers nom de page
    def self.page_name_for(controller, action)
      mapping = {
        "pages#home" => Pages::HOME,
        "pages#index" => Pages::HOME,
        "pages#about" => Pages::ABOUT,
        "pages#contact" => Pages::CONTACT,

        "client/shops#index" => Pages::SHOPS_INDEX,
        "client/shops#show" => Pages::SHOPS_SHOW,
        "client/shops#search" => Pages::SHOPS_SEARCH,

        "client/items#index" => Pages::ITEMS_INDEX,
        "client/items#show" => Pages::ITEMS_SHOW,
        "client/items#search" => Pages::ITEMS_SEARCH,

        "client/carts#show" => Pages::CART,

        "client/checkouts#new" => Pages::CHECKOUT,
        "client/checkouts#delivery" => Pages::CHECKOUT_DELIVERY,
        "client/checkouts#payment" => Pages::CHECKOUT_PAYMENT,
        "client/checkouts#confirm" => Pages::CHECKOUT_CONFIRMATION,

        "client/orders#show" => Pages::USER_ORDERS,
        "client/users#show" => Pages::USER_PROFILE,
        "client/addresses#index" => Pages::USER_ADDRESSES,

        "vendors/dashboard#index" => Pages::VENDOR_DASHBOARD,
        "vendors/items#index" => Pages::VENDOR_PRODUCTS,
        "vendors/items#new" => Pages::VENDOR_PRODUCT_NEW,
        "vendors/items#create" => Pages::VENDOR_PRODUCT_NEW,
        "vendors/items#edit" => Pages::VENDOR_PRODUCT_EDIT,
        "vendors/items#update" => Pages::VENDOR_PRODUCT_EDIT,
        "vendors/items#show" => Pages::VENDOR_PRODUCT_EDIT,
        "vendors/orders#index" => Pages::VENDOR_ORDERS,
        "vendors/orders#show" => Pages::VENDOR_ORDER_SHOW,
        "vendors/settings#index" => Pages::VENDOR_SETTINGS,
        "vendors/settings#edit" => Pages::VENDOR_SETTINGS,
        "vendors/shops#edit" => Pages::VENDOR_SHOP_EDIT,
        "vendors/shops#update" => Pages::VENDOR_SHOP_EDIT,
        "vendors/analytics#index" => Pages::VENDOR_ANALYTICS,

        "employees/dashboards#show" => Pages::EMPLOYEE_DASHBOARD,
        "employees/items#index" => Pages::EMPLOYEE_PRODUCTS,
        "employees/items#new" => Pages::EMPLOYEE_PRODUCT_NEW,
        "employees/items#create" => Pages::EMPLOYEE_PRODUCT_NEW,
        "employees/items#edit" => Pages::EMPLOYEE_PRODUCT_EDIT,
        "employees/items#update" => Pages::EMPLOYEE_PRODUCT_EDIT,
        "employees/items#show" => Pages::EMPLOYEE_PRODUCT_EDIT,
        "employees/orders#index" => Pages::EMPLOYEE_ORDERS,
        "employees/orders#show" => Pages::EMPLOYEE_ORDER_SHOW,
        "employees/analytics#index" => Pages::EMPLOYEE_ANALYTICS,

        "sessions#new" => Pages::SIGN_IN,
        "users#new" => Pages::SIGN_UP,
        "passwords#new" => Pages::PASSWORD_RESET,

        "maintenance#show" => Pages::MAINTENANCE,
        "maintenance#confirmation" => Pages::MAINTENANCE_CONFIRMATION
      }

      key = "#{controller}##{action}"
      mapping[key] || "#{controller}_#{action}".parameterize(separator: "_")
    end
  end
end
