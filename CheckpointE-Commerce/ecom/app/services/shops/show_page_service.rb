# frozen_string_literal: true

module Shops
  # Service pour charger les données nécessaires à l'affichage de la page d'une boutique
  class ShowPageService
    attr_reader :shop, :items, :sub_categories, :promo_items

    def initialize(shop:, page: 1, per_page: 12)
      @shop = shop
      @page = page
      @per_page = per_page
    end

    def call
      load_items
      load_sub_categories
      load_promo_items
      self
    end

    private

    def load_items
      @items = @shop.items
                     .available_for_sale
                     .includes(:shop, :currency, :variants, main_image_attachment: :blob, images_attachments: :blob)
                     .order(created_at: :desc)
                     .page(@page)
                     .per(@per_page)
    end

    def load_sub_categories
      # Charger les sous-catégories uniques des produits de la boutique
      # via la relation inverse Item -> ProductSubCategory
      sub_category_ids = @shop.items
                               .available_for_sale
                               .where.not(product_sub_category_id: nil)
                               .distinct
                               .pluck(:product_sub_category_id)

      @sub_categories = ProductSubCategory
                          .where(id: sub_category_ids)
                          .includes(:product_category)
                          .with_attached_icon
                          .limit(6)
    end

    def load_promo_items
      # Charger quelques produits pour les promotions
      # Prioriser les produits en promo, sinon prendre les plus récents
      @promo_items = @shop.items
                          .available_for_sale
                          .includes(:shop, :currency, :variants, main_image_attachment: :blob, images_attachments: :blob)
                          .order(Arel.sql("CASE WHEN is_on_sale = true THEN 0 ELSE 1 END"), created_at: :desc)
                          .limit(10)
                          .to_a
    end
  end
end
