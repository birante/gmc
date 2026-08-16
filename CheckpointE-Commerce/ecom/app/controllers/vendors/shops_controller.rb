module Vendors
  class ShopsController < BaseController
    skip_before_action :authenticate_vendor_or_employee, only: [ :new, :create ]
    skip_before_action :require_verified_vendor_account!, only: [ :new, :create ]
    skip_before_action :require_shop!, only: [ :new, :create ]
    before_action :set_shop, only: [ :edit, :update ]
    before_action :ensure_vendor_verified_for_shop_creation, only: [ :new, :create ]

    # Définir le layout selon l'action
    layout :determine_layout

    def new
      @vendor = current_vendor
      unless @vendor
        redirect_to new_vendors_session_path, alert: t("vendors.authentication.must_be_logged_in_with_period")
        return
      end
      # Vérifier que le vendor n'a pas déjà une boutique
      if @vendor.shops.any?
        redirect_to vendors_dashboard_path, notice: "Vous avez déjà une boutique."
        return
      end
      @shop = @vendor.shops.build
      @shop.build_legal_info
      @shop.contacts.build
      @sectors = Sector.where(is_active: true).order(:position)
    end

    def create
      @vendor = current_vendor
      unless @vendor
        redirect_to new_vendors_session_path, alert: t("vendors.authentication.must_be_logged_in_with_period")
        return
      end
      Rails.logger.info("🏪 [Vendors::ShopsController] Création boutique - vendor_id: #{@vendor.id}, nom: #{shop_params[:name]}")
      @shop = @vendor.shops.build(shop_params)
      if @shop.save
        Rails.logger.info("✅ [Vendors::ShopsController] Boutique créée avec succès - shop_id: #{@shop.id}, slug: #{@shop.slug}, vendor_id: #{@vendor.id}")
        # Rediriger vers la sélection de plan (étape obligatoire)
        redirect_to new_vendors_plan_path, notice: t("vendors.shops.shop_created_select_plan")
      else
        Rails.logger.warn("⚠️ [Vendors::ShopsController] Échec création boutique - vendor_id: #{@vendor.id}, erreurs: #{@shop.errors.full_messages.join(', ')}")
        @sectors = Sector.where(is_active: true).order(:position)
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @vendor = current_vendor
      @shops = @vendor.shops.order(created_at: :desc)
      @sectors = Sector.where(is_active: true).order(:position)
      @social_platforms = SocialPlatform.where(is_active: true).order(:position)
      @payment_methods = PaymentMethod.where(is_active: true).order(:id)

      # Charger les données pour les sélecteurs de liens CTA
      @product_categories = ProductCategory.where(is_active: true).includes(:sub_categories).order(:position, :name)
      @shop_items = @shop.items.where(validation_status: "approved").order(:name).limit(100) if @shop

      # Préparer les données JSON pour le JavaScript
      @categories_json = @product_categories.map do |cat|
        {
          id: cat.id,
          slug: cat.slug,
          name: cat.name,
          sub_categories: cat.sub_categories.where(is_active: true).map { |sub| { id: sub.id, slug: sub.slug, name: sub.name } }
        }
      end.to_json

      @items_json = (@shop_items || []).map do |item|
        {
          id: item.id,
          slug: item.slug || item.friendly_id,
          name: item.name
        }
      end.to_json
    end

    def update
      @vendor = current_vendor
      Rails.logger.info("✏️ [Vendors::ShopsController] Mise à jour boutique - shop_id: #{@shop.id}, vendor_id: #{@vendor.id}")

      if @shop.update(shop_params)
        Rails.logger.info("✅ [Vendors::ShopsController] Boutique mise à jour avec succès - shop_id: #{@shop.id}, slug: #{@shop.slug}")
        # Rediriger avec le slug de la boutique mise à jour
        redirect_to helpers.url_with_shop(vendors_dashboard_path, @shop), notice: "Boutique mise à jour avec succès"
      else
        Rails.logger.warn("⚠️ [Vendors::ShopsController] Échec mise à jour boutique - shop_id: #{@shop.id}, erreurs: #{@shop.errors.full_messages.join(', ')}")
        @shops = @vendor.shops.order(created_at: :desc)
        @sectors = Sector.where(is_active: true).order(:position)
        @social_platforms = SocialPlatform.where(is_active: true).order(:position)
        @payment_methods = PaymentMethod.where(is_active: true).order(:id)
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy_logo
      @vendor = current_vendor
      Rails.logger.info("🗑️ [Vendors::ShopsController] Suppression logo - shop_id: #{@shop.id}, vendor_id: #{@vendor.id}")

      if @shop.logo.attached?
        @shop.logo.purge
        Rails.logger.info("✅ [Vendors::ShopsController] Logo supprimé avec succès - shop_id: #{@shop.id}")

        respond_to do |format|
          format.turbo_stream
          format.html { redirect_to edit_vendors_shop_path(@shop), notice: "Logo supprimé avec succès" }
        end
      else
        respond_to do |format|
          format.turbo_stream { render turbo_stream: turbo_stream.replace("logo-section", partial: "vendors/shops/logo_section", locals: { shop: @shop }) }
          format.html { redirect_to edit_vendors_shop_path(@shop), alert: "Aucun logo à supprimer" }
        end
      end
    rescue => e
      Rails.logger.error("❌ [Vendors::ShopsController] Erreur suppression logo - shop_id: #{@shop.id}, erreur: #{e.message}")
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("logo-section", partial: "vendors/shops/logo_section", locals: { shop: @shop }) }
        format.html { redirect_to edit_vendors_shop_path(@shop), alert: "Erreur lors de la suppression du logo" }
      end
    end

    private

    def ensure_vendor_verified_for_shop_creation
      vendor = current_vendor
      return unless vendor

      unless vendor.verified?
        Rails.logger.warn("⚠️ [Vendors::ShopsController] Tentative de création de boutique avec compte non vérifié - vendor_id: #{vendor.id}")
        session[:return_to_after_verification] = new_vendors_shop_path
        session[:pending_verification_email] = vendor.email if vendor.email.present?
        redirect_to new_vendors_verification_path, alert: "Vous devez vérifier votre compte avant de créer une boutique."
        nil
      end
    end

    def determine_layout
      case action_name
      when "new", "create"
        "vendor_onboarding"
      else
        "vendor"
      end
    end

    def set_shop
      @shop = current_vendor.shops
                            .includes(social_links: :social_platform)
                            .friendly
                            .find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to vendors_dashboard_path, alert: "Boutique non trouvée"
    end

    def shop_params
      params.require(:shop).permit(
        :name, :address, :description, :primary_color, :secondary_color, :status,
        :logo,
        legal_info_attributes: [ :id, :rc_number, :ninea_number, :legal_form ],
        contacts_attributes: [ :id, :phone_number, :country_code, :is_whatsapp, :_destroy ],
        social_links_attributes: [ :id, :social_platform_id, :url, :_destroy ],
        shop_payment_methods_attributes: [ :id, :payment_method_id, :is_active, :_destroy ],
        shop_banners_attributes: [ :id, :title, :cta_text, :cta_link, :position, :image, :_destroy ],
        sector_ids: []
      )
    end
  end
end
