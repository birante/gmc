# frozen_string_literal: true

class ShopPageHeaderSlide < ApplicationRecord
  belongs_to :shop

  has_one_attached :image
  has_one_attached :image_tablet
  has_one_attached :image_mobile

  scope :ordered, -> { order(:position) }

  validates :position, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def self.ransackable_attributes(_auth_object = nil)
    [ "id", "shop_id", "link", "button_text", "position", "created_at", "updated_at" ]
  end

  def self.ransackable_associations(_auth_object = nil)
    [ "shop" ]
  end
end
