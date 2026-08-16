# frozen_string_literal: true

class HomePageSectionSideBanner < ApplicationRecord
  belongs_to :home_page_section

  has_one_attached :image

  scope :active, -> { where(is_active: true) }
  scope :ordered, -> { order(:position) }

  validates :title, presence: true
  validates :cta_link, presence: true

  def self.ransackable_attributes(_auth_object = nil)
    [ "bg_color", "created_at", "cta_link", "cta_text", "description",
     "home_page_section_id", "id", "is_active", "position", "subtitle",
     "text_color", "title", "updated_at" ]
  end

  def self.ransackable_associations(_auth_object = nil)
    [ "home_page_section", "image_attachment", "image_blob" ]
  end
end
