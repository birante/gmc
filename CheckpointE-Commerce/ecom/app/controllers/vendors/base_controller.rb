module Vendors
  class BaseController < ApplicationController
    include VendorShopContext

    layout "vendor"

    before_action :authenticate_vendor_or_employee
    before_action :require_verified_vendor_account!
    before_action :require_shop!
    before_action :set_vendor_for_view

    # Rendre url_with_shop disponible dans les contrôleurs
    helper VendorsHelper
    include VendorsHelper

    def self.allow_unauthenticated_access(**options)
      skip_before_action :authenticate_vendor_or_employee, **options
    end

    private

    def require_authentication
    end

    def authenticate_vendor_or_employee
      unless current_vendor || current_employee
        redirect_to new_vendors_session_path, alert: t("vendors.authentication.must_be_logged_in")
        nil
      end
    end

    helper_method :vendor_signed_in?, :current_vendor_or_employee, :acting_as_vendor?

    def vendor_signed_in?
      current_vendor.present?
    end

    def current_vendor_or_employee
      current_vendor || current_employee&.vendor
    end

    def acting_as_vendor?
      current_vendor.present?
    end

    def require_verified_vendor_account!
      vendor = current_vendor
      return unless vendor # Les employés peuvent accéder même si le vendor n'est pas vérifié (géré par leur propre logique)

      unless vendor.verified?
        Rails.logger.warn("⚠️ [Vendors::BaseController] Tentative d'accès avec compte vendor non vérifié - vendor_id: #{vendor.id}")
        # Sauvegarder l'URL de retour pour rediriger après vérification
        session[:return_to_after_verification] = request.url
        # Stocker les infos pour la page de vérification
        session[:pending_verification_email] = vendor.email if vendor.email.present?
        redirect_to new_vendors_verification_path, alert: "Vous devez vérifier votre compte avant de continuer."
        nil
      end
    end

    def require_shop!
      vendor = current_vendor
      return unless vendor # Les employés ont leurs propres boutiques assignées

      if vendor.shops.empty?
        Rails.logger.warn("⚠️ [Vendors::BaseController] Tentative d'accès sans boutique - vendor_id: #{vendor.id}")
        redirect_to new_vendors_shop_path, alert: "Vous devez créer une boutique avant de continuer."
        nil
      end
    end

    def set_vendor_for_view
      if current_employee
        @vendor = current_employee.vendor
        @shops = current_employee.shops.order(created_at: :desc)
      else
        @vendor = current_vendor
        @shops = current_vendor&.shops&.order(created_at: :desc) || []
      end
    end
  end
end
