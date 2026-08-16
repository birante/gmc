# frozen_string_literal: true

class ShopPageSectionCategory < ApplicationRecord
  belongs_to :shop_page_section
  belongs_to :product_sub_category

  scope :ordered, -> { order(:position) }

  validates :position, presence: true
  validates :product_sub_category_id, uniqueness: { scope: :shop_page_section_id, message: "est déjà dans cette section" }

  def self.ransackable_attributes(_auth_object = nil)
    [ "id", "shop_page_section_id", "product_sub_category_id", "position", "created_at", "updated_at" ]
  end

  def self.ransackable_associations(_auth_object = nil)
    [ "shop_page_section", "product_sub_category" ]
  end
end
