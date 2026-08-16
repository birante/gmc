class SecondaryBanner < ApplicationRecord
  belongs_to :home_page_section

  has_one_attached :image
  has_one_attached :image_mobile

  def self.ransackable_attributes(auth_object = nil)
    [ "created_at", "gradient_from", "gradient_to", "home_page_section_id", "id", "position_order", "position_type", "title", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "home_page_section", "image_attachment", "image_blob", "image_mobile_attachment", "image_mobile_blob" ]
  end
end
