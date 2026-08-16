# frozen_string_literal: true

module Shops
  # Service pour charger les données digitalisées de la page boutique (header, sections, produits, catégories)
  class ShowPageDataService
    attr_reader :shop

    def initialize(shop:)
      @shop = shop
    end

    def call
      {
        shop_page_header_slides: shop_page_header_slides,
        shop_page_sections: shop_page_sections
      }
    end

    def shop_page_header_slides
      @shop_page_header_slides ||= shop.shop_page_header_slides.ordered.includes(image_attachment: :blob).to_a
    end

    def shop_page_sections
      @shop_page_sections ||= shop.shop_page_sections
                                   .active
                                   .ordered
                                   .includes(
                                     :shop_page_section_products,
                                     :shop_page_section_categories,
                                     shop_page_section_products: { item: [ :variants, :currency, { main_image_attachment: :blob }, { images_attachments: :blob } ] },
                                     shop_page_section_categories: { product_sub_category: [ :product_category, { icon_attachment: :blob } ] }
                                   )
                                   .to_a
    end
  end
end
