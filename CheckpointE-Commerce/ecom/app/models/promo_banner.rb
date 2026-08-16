class PromoBanner < ApplicationRecord
  belongs_to :home_page_section

  has_one_attached :image
  has_one_attached :image_mobile
  has_one_attached :overlay_image

  scope :ordered, -> { order(:position) }

  def self.ransackable_attributes(auth_object = nil)
    [ "created_at", "cta_link", "cta_text", "home_page_section_id", "id", "position", "title", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "home_page_section", "image_attachment", "image_blob", "image_mobile_attachment", "image_mobile_blob", "overlay_image_attachment", "overlay_image_blob" ]
  end
end
