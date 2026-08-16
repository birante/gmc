# frozen_string_literal: true

class HomePageSectionProduct < ApplicationRecord
  belongs_to :home_page_section
  belongs_to :item

  scope :active, -> { where(is_active: true) }
  scope :ordered, -> { order(:position) }

  validates :position, presence: true
  validates :item_id, uniqueness: { scope: :home_page_section_id, message: "est déjà dans cette section" }

  def self.ransackable_attributes(_auth_object = nil)
    [ "created_at", "home_page_section_id", "id", "is_active", "item_id", "position", "updated_at" ]
  end

  def self.ransackable_associations(_auth_object = nil)
    [ "home_page_section", "item" ]
  end
end
