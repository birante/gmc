# frozen_string_literal: true

class ShopPageHeader < ApplicationRecord
  belongs_to :shop

  has_one_attached :image

  validates :shop_id, uniqueness: true

  def self.ransackable_attributes(_auth_object = nil)
    [ "id", "shop_id", "link", "button_text", "created_at", "updated_at" ]
  end

  def self.ransackable_associations(_auth_object = nil)
    [ "shop" ]
  end
end
