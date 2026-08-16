# frozen_string_literal: true

class HomePageSectionItem < ApplicationRecord
  belongs_to :home_page_section

  has_one_attached :image

  scope :active, -> { where(is_active: true) }
  scope :ordered, -> { order(:position) }

  validates :title, presence: true
  validates :link, presence: true
  validates :position, presence: true

  def self.ransackable_attributes(_auth_object = nil)
    [ "created_at", "home_page_section_id", "id", "is_active", "link", "position", "title", "updated_at" ]
  end

  def self.ransackable_associations(_auth_object = nil)
    [ "home_page_section", "image_attachment", "image_blob" ]
  end
end
