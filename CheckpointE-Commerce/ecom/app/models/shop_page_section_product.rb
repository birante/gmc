# frozen_string_literal: true

class ShopPageSectionProduct < ApplicationRecord
  belongs_to :shop_page_section
  belongs_to :item

  scope :active, -> { where(is_active: true) }
  scope :ordered, -> { order(:position) }

  validates :position, presence: true
  validates :item_id, uniqueness: { scope: :shop_page_section_id, message: "est déjà dans cette section" }

  validate :item_belongs_to_shop

  def self.ransackable_attributes(_auth_object = nil)
    [ "id", "shop_page_section_id", "item_id", "position", "is_active", "created_at", "updated_at" ]
  end

  def self.ransackable_associations(_auth_object = nil)
    [ "shop_page_section", "item" ]
  end

  private

  def item_belongs_to_shop
    return unless shop_page_section && item

    if item.shop_id != shop_page_section.shop_id
      errors.add(:item_id, "doit appartenir à la boutique de cette section")
    end
  end
end
