# frozen_string_literal: true

class ShopPageSection < ApplicationRecord
  SECTION_TYPES = %w[
    hero_carousel
    promo_banners
    global_carousels
    categories_carousels
    featured_categories
    products
  ].freeze

  belongs_to :shop
  has_many :shop_page_section_products, dependent: :destroy
  has_many :shop_page_section_categories, dependent: :destroy

  has_many :items, through: :shop_page_section_products
  has_many :product_sub_categories, through: :shop_page_section_categories

  scope :active, -> { where(is_active: true) }
  scope :inactive, -> { where(is_active: false) }
  scope :ordered, -> { order(:position) }

  validates :section_type, presence: true, inclusion: { in: SECTION_TYPES }
  validates :position, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def self.ransackable_attributes(_auth_object = nil)
    [ "id", "shop_id", "section_type", "title", "description", "position", "is_active", "created_at", "updated_at" ]
  end

  def self.ransackable_associations(_auth_object = nil)
    [ "shop", "shop_page_section_products", "shop_page_section_categories", "items", "product_sub_categories" ]
  end
end
