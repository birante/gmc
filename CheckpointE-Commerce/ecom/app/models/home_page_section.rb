class HomePageSection < ApplicationRecord
  has_one_attached :marquee_image
  has_one_attached :marquee_image_mobile

  has_many :hero_slider_slides, dependent: :destroy
  has_many :promo_banners, dependent: :destroy
  has_many :official_brand_banners, dependent: :destroy
  has_many :local_shop_banners, dependent: :destroy
  has_many :secondary_banners, dependent: :destroy
  has_many :home_page_section_categories, dependent: :destroy
  has_many :home_page_section_items, dependent: :destroy
  has_many :home_page_section_groups, dependent: :destroy
  has_many :home_page_section_settings, dependent: :destroy
  has_many :home_page_section_products, dependent: :destroy
  has_many :home_page_section_side_banners, dependent: :destroy
  has_many :shop_spotlights, dependent: :destroy

  scope :active, -> { where(is_active: true) }
  scope :inactive, -> { where(is_active: false) }

  def self.ransackable_attributes(auth_object = nil)
    [ "created_at", "description", "id", "is_active", "position", "section_type", "title", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "hero_slider_slides", "promo_banners", "official_brand_banners", "local_shop_banners", "secondary_banners", "home_page_section_categories", "home_page_section_items", "home_page_section_groups", "home_page_section_settings", "home_page_section_products", "home_page_section_side_banners", "shop_spotlights" ]
  end
end
