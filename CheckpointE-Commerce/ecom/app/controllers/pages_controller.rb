# frozen_string_literal: true

class PagesController < ApplicationController
  allow_unauthenticated_access

  # GET /soon — page de redirection pour les liens / sections pas encore disponibles.
  def coming_soon
    @page_title = t("pages.coming_soon.page_title", default: "Cette page arrive bientôt | aa")
    @meta_description = t("pages.coming_soon.meta_description", default: "Cette section de aa 2.0 sera bientôt disponible.")
  end

  def home
    data = ::Pages::HomeDataService.new.call

    # Utiliser le cache Rails pour les données lourdes
    # Invalider le cache quand les données changent
    @marquee_section = data[:marquee_section]
    @hero_slider_slides = data[:hero_slider_slides]
    @promo_banners = data[:promo_banners]
    @secondary_banners = data[:secondary_banners]
    @trending_groups = data[:trending_groups]
    @featured_items = data[:featured_items]
    @promo_items = data[:promo_items]
    @promo_carousel_settings = data[:promo_carousel_settings]
    @flash_items = data[:flash_items]
    @categories = data[:categories]
    @sub_categories = data[:sub_categories]
    @local_shops = data[:local_shops]
    @local_shops_banner = data[:local_shops_banner]
    @official_shops = data[:official_shops]
    @shop_spotlights = data[:shop_spotlights]
    @made_in_senegal_items = data[:made_in_senegal_items]
    @navbar_categories = data[:navbar_categories] # Eager-loaded pour la navbar
  end

  def become_vendor
    # Page marketing pour devenir vendeur
  end

  def terms
    # Page des conditions d'utilisation
  end

  def privacy
    # Page de politique de confidentialité
  end

  def about
    @about_stats = Rails.cache.fetch("pages/about/stats", expires_in: 1.hour) do
      {
        shops_count: Shop.active.count,
        items_count: Item.available_for_sale.count
      }
    end
  end

  def contact
    @contact_message = ContactMessage.new
  end

  def contact_create
    @contact_message = ContactMessage.new(contact_message_params).tap do |m|
      m.ip_address = request.remote_ip
      m.user_agent = request.user_agent
    end

    if @contact_message.save
      redirect_to contact_path, notice: t("pages.contact.flash.success", default: "Merci, votre message a bien été envoyé. Nous revenons vers vous rapidement.")
    else
      flash.now[:alert] = t("pages.contact.flash.error", default: "Veuillez corriger les erreurs ci-dessous.")
      render :contact, status: :unprocessable_entity
    end
  end

  private

  def contact_message_params
    params.require(:contact_message).permit(:first_name, :last_name, :email, :phone, :subject, :message)
  end
end
