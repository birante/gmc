# frozen_string_literal: true

module Pages
  # Service pour charger et cacher les données de la home
  class HomeDataService
    def initialize(locale: I18n.locale)
      @locale = locale
      @timestamps = nil # Memoization des timestamps
    end

    def call
      {
        marquee_section: cached_marquee_section,
        hero_slider_slides: cached_hero_slider_slides,
        promo_banners: cached_promo_banners,
        secondary_banners: cached_secondary_banners,
        trending_groups: cached_trending_groups,
        featured_items: cached_featured_items,
        promo_items: cached_promo_items,
        promo_carousel_settings: cached_promo_carousel_settings,
        flash_items: cached_flash_items,
        categories: cached_categories,
        sub_categories: cached_sub_categories,
        local_shops: cached_local_shops,
        local_shops_banner: cached_local_shops_banner,
        official_shops: cached_official_shops,
        shop_spotlights: cached_shop_spotlights,
        made_in_senegal_items: cached_made_in_senegal_items,
        navbar_categories: cached_navbar_categories,
        cache_etag: cache_etag,
        last_data_update: last_data_update
      }
    end

    private

    # ====== TIMESTAMP HELPER ======
    # Charge tous les timestamps en une seule fois pour éviter N+1 queries
    def timestamps
      @timestamps ||= Rails.cache.fetch("home/all_timestamps/v1", expires_in: 5.minutes) do
        {
          hero_slider_slides: HeroSliderSlide.maximum(:updated_at)&.to_i,
          promo_banners: PromoBanner.maximum(:updated_at)&.to_i,
          secondary_banners: SecondaryBanner.maximum(:updated_at)&.to_i,
          section_groups: HomePageSectionGroup.maximum(:updated_at)&.to_i,
          section_products: HomePageSectionProduct.maximum(:updated_at)&.to_i,
          section_settings: HomePageSectionSetting.maximum(:updated_at)&.to_i,
          section_items: HomePageSectionItem.maximum(:updated_at)&.to_i,
          local_shop_banners: LocalShopBanner.maximum(:updated_at)&.to_i,
          side_banners: HomePageSectionSideBanner.maximum(:updated_at)&.to_i,
          official_brands: OfficialBrandBanner.maximum(:updated_at)&.to_i,
          shop_spotlights: ShopSpotlight.maximum(:updated_at)&.to_i,
          items: Item.maximum(:updated_at)&.to_i,
          categories: ProductCategory.maximum(:updated_at)&.to_i,
          sub_categories: ProductSubCategory.maximum(:updated_at)&.to_i,
          shops: Shop.maximum(:updated_at)&.to_i
        }
      end
    end

    # ====== CACHED DATA METHODS ======

    def cached_marquee_section
      stamp = HomePageSection.where(section_type: "marquee").maximum(:updated_at)&.to_i
      Rails.cache.fetch("home/marquee_section/v1/#{stamp}", expires_in: 30.minutes) do
        HomePageSection.where(section_type: "marquee", is_active: true)
                       .includes(marquee_image_attachment: :blob, marquee_image_mobile_attachment: :blob)
                       .first
      end
    end

    def cached_hero_slider_slides
      cache_key = "home/hero_slider_slides/v1/#{timestamps[:hero_slider_slides]}"
      Rails.cache.fetch(cache_key, expires_in: 30.minutes) do
        HeroSliderSlide.joins(:home_page_section)
                       .where(home_page_sections: { section_type: "hero_slider" })
                       .includes(:home_page_section, image_attachment: :blob, image_mobile_attachment: :blob)
                       .order(:position)
                       .to_a
      end
    end

    def cached_promo_banners
      cache_key = "home/promo_banners/v1/#{timestamps[:promo_banners]}"
      Rails.cache.fetch(cache_key, expires_in: 30.minutes) do
        PromoBanner.joins(:home_page_section)
                   .where(home_page_sections: { section_type: "promo_banners" })
                   .includes(:home_page_section, image_attachment: :blob, image_mobile_attachment: :blob, overlay_image_attachment: :blob)
                   .order(:position)
                   .to_a
      end
    end

    def cached_secondary_banners
      cache_key = "home/secondary_banners/v1/#{timestamps[:secondary_banners]}"
      Rails.cache.fetch(cache_key, expires_in: 30.minutes) do
        SecondaryBanner.joins(:home_page_section)
                       .where(home_page_sections: { section_type: "secondary_banners" })
                       .includes(:home_page_section, image_attachment: :blob, image_mobile_attachment: :blob)
                       .order(:position_order)
                       .to_a
      end
    end

    def cached_trending_groups
      cache_key = "home/trending_groups/v1/#{timestamps[:section_groups]}"
      Rails.cache.fetch(cache_key, expires_in: 30.minutes) do
        HomePageSectionGroup.joins(:home_page_section)
                            .where(home_page_sections: { section_type: "trending_categories" })
                            .includes(home_page_section_group_items: { image_attachment: :blob })
                            .active
                            .ordered
                            .to_a
      end
    end

    # 🚀 Navbar categories avec eager-loading pour éviter N+1
    def cached_navbar_categories
      Rails.cache.fetch("home/navbar_categories/v2", expires_in: 1.hour) do
        ProductCategory.where(is_active: true)
                       .order(position: :asc)
                       .includes(sub_categories: { icon_attachment: :blob })
                       .to_a
      end
    end

    def cached_featured_items
      Rails.cache.fetch("home/featured_items/v4", expires_in: 15.minutes) do
        Item.available_for_sale
            .order(created_at: :desc)
            .limit(12)
            .to_a
      end
    end

    def cached_promo_items
      products_stamp = HomePageSectionProduct.maximum(:updated_at)&.to_i
      settings_stamp = HomePageSectionSetting.maximum(:updated_at)&.to_i
      Rails.cache.fetch("home/promo_items/v4/#{products_stamp}/#{settings_stamp}", expires_in: 15.minutes) do
        manual_promo_items
      end
    end

    def cached_promo_carousel_settings
      settings_stamp = HomePageSectionSetting.maximum(:updated_at)&.to_i
      sections_stamp = HomePageSection.maximum(:updated_at)&.to_i
      Rails.cache.fetch("home/promo_carousel_settings/v1/#{sections_stamp}/#{settings_stamp}", expires_in: 30.minutes) do
        promo_carousel_section&.home_page_section_settings&.each_with_object({}) do |setting, memo|
          memo[setting.key] = setting.value
        end || {}
      end
    end

    def promo_carousel_section
      @promo_carousel_section ||= HomePageSection
        .includes(:home_page_section_settings, :home_page_section_products)
        .find_by(section_type: "promo_carousel", is_active: true)
    end

    def manual_promo_items
      # Essayer d'abord les produits via HomePageSectionProduct
      section_products = promo_carousel_section&.home_page_section_products
                                                &.active
                                                &.ordered
                                                &.includes(item: [
                                                  :shop,
                                                  :currency,
                                                  variants: [],
                                                  main_image_attachment: :blob,
                                                  images_attachments: :blob
                                                ])
                                                &.map(&:item)
                                                &.compact || []

      return section_products if section_products.any?

      # Sinon utiliser les item_ids du setting (méthode legacy)
      item_ids = promo_carousel_item_ids
      return [] if item_ids.empty?

      items = Item.available_for_sale
                  .where(id: item_ids)
                  .includes(
                    :shop,
                    :currency,
                    variants: [],
                    main_image_attachment: :blob,
                    images_attachments: :blob
                  )
                  .to_a

      items.sort_by { |item| item_ids.index(item.id) }
    end

    def promo_carousel_item_ids
      raw_ids = cached_promo_carousel_settings["item_ids"].to_s
      raw_ids
        .split(/[\s,;]+/)
        .map(&:strip)
        .reject(&:blank?)
        .map(&:to_i)
        .reject(&:zero?)
        .uniq
    end

    def cached_flash_items
      Rails.cache.fetch("home/flash_items/v3", expires_in: 15.minutes) do
        Item.available_for_sale
            .order(Arel.sql("RANDOM()"))
            .limit(6)
            .to_a
      end
    end

    def cached_categories
      cache_key = "home/categories/v1/#{timestamps[:section_items]}"
      Rails.cache.fetch(cache_key, expires_in: 30.minutes) do
        HomePageSectionItem.joins(:home_page_section)
                           .where(home_page_sections: { section_type: "categories" })
                           .includes(:home_page_section, image_attachment: :blob)
                           .active
                           .ordered
                           .to_a
      end
    end

    def cached_sub_categories
      Rails.cache.fetch("home/sub_categories/v3", expires_in: 30.minutes) do
        ProductSubCategory.where(is_active: true)
                          .eager_load(:product_category)
                          .includes(
                            icon_attachment: {
                              blob: {
                                variant_records: { image_attachment: :blob }
                              }
                            }
                          )
                          .limit(16)
                          .to_a
      end
    end

    def cached_local_shops
      cache_key = "home/local_shop_banners/v1/#{timestamps[:local_shop_banners]}"
      Rails.cache.fetch(cache_key, expires_in: 30.minutes) do
        LocalShopBanner.active
                       .joins(:home_page_section)
                       .where(home_page_sections: { section_type: "local_shops" })
                       .includes(:home_page_section, image_attachment: :blob)
                       .order(:position)
                       .to_a
      end
    end

    def cached_local_shops_banner
      cache_key = "home/local_shops_side_banner/v1/#{timestamps[:side_banners]}"
      Rails.cache.fetch(cache_key, expires_in: 30.minutes) do
        HomePageSectionSideBanner.joins(:home_page_section)
                                  .where(home_page_sections: { section_type: "local_shops" })
                                  .includes(:home_page_section, image_attachment: :blob)
                                  .active
                                  .ordered
                                  .first
      end
    end

    def cached_official_shops
      cache_key = "home/official_brand_banners/v1/#{timestamps[:official_brands]}"
      Rails.cache.fetch(cache_key, expires_in: 30.minutes) do
        # Charger les bannières de marques officielles configurées via ActiveAdmin
        OfficialBrandBanner.joins(:home_page_section)
                           .where(home_page_sections: { section_type: "official_brands", is_active: true })
                           .includes(image_attachment: :blob)
                           .order(:position)
                           .limit(20)
                           .to_a
      end
    end

    def cached_shop_spotlights
      cache_key = "home/shop_spotlights/v3/#{timestamps[:shop_spotlights]}"
      Rails.cache.fetch(cache_key, expires_in: 30.minutes) do
        spotlights = ShopSpotlight.joins(:home_page_section)
                     .where(home_page_sections: { section_type: "shop_spotlight", is_active: true })
                     .includes(
                       promo_image_attachment: :blob,
                       shop: [ { logo_attachment: :blob }, :sectors ]
                     )
                     .order(:position)
                     .to_a

        # Pré-charger tous les items des spotlights en une seule requête
        all_item_ids = spotlights.flat_map(&:item_ids_array).uniq.compact
        if all_item_ids.any?
          items_by_id = Item.available_for_sale
                           .where(id: all_item_ids)
                           .includes(
                             :shop,
                             :currency,
                             variants: [],
                             main_image_attachment: :blob,
                             images_attachments: :blob
                           )
                           .index_by(&:id)

          # Associer les items aux spotlights
          spotlights.each do |spotlight|
            items = spotlight.item_ids_array.map { |id| items_by_id[id] }.compact
            spotlight.instance_variable_set(:@items, items)
          end
        end

        spotlights
      end
    end

    def cached_made_in_senegal_items
      cache_key = "home/made_in_senegal_products/v1/#{timestamps[:section_products]}"
      Rails.cache.fetch(cache_key, expires_in: 15.minutes) do
        # Charger les produits configurés via ActiveAdmin pour la section local_shops
        section_products = HomePageSectionProduct.joins(:home_page_section)
                                                  .where(home_page_sections: { section_type: "local_shops" })
                                                  .includes(item: [
                                                    :shop,
                                                    :product_sub_category,
                                                    :currency,
                                                    variants: [],
                                                    main_image_attachment: :blob,
                                                    images_attachments: :blob
                                                  ])
                                                  .active
                                                  .ordered
                                                  .limit(6)
                                                  .to_a

        # Retourner les items liés
        section_products.map(&:item).compact
      end
    end

    # ====== HTTP CACHING HELPERS ======

    def cache_etag
      # ETag basé sur les timestamps des dernières modifications
      # Utiliser le cache pour éviter les requêtes à chaque fois
      Rails.cache.fetch("home/cache_etag/v1", expires_in: 5.minutes) do
        [
          Item.maximum(:updated_at),
          HeroSliderSlide.maximum(:updated_at),
          PromoBanner.maximum(:updated_at),
          SecondaryBanner.maximum(:updated_at),
          HomePageSectionGroup.maximum(:updated_at),
          HomePageSectionGroupItem.maximum(:updated_at),
          HomePageSectionItem.maximum(:updated_at),
          ProductCategory.maximum(:updated_at),
          ProductSubCategory.maximum(:updated_at),
          Shop.maximum(:updated_at),
          @locale
        ]
      end
    end

    def last_data_update
      # Dernière modification parmi toutes les données affichées
      # Utiliser le cache pour éviter les requêtes à chaque fois
      Rails.cache.fetch("home/last_data_update/v1", expires_in: 5.minutes) do
        [
          Item.maximum(:updated_at),
          HeroSliderSlide.maximum(:updated_at),
          PromoBanner.maximum(:updated_at),
          SecondaryBanner.maximum(:updated_at),
          HomePageSectionGroup.maximum(:updated_at),
          HomePageSectionGroupItem.maximum(:updated_at),
          HomePageSectionItem.maximum(:updated_at),
          ProductCategory.maximum(:updated_at),
          ProductSubCategory.maximum(:updated_at),
          Shop.maximum(:updated_at)
        ].compact.max || Time.current
      end
    end
  end
end
