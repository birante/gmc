class OfficialBrandBanner < ApplicationRecord
  belongs_to :home_page_section

  has_one_attached :image

  def self.ransackable_attributes(auth_object = nil)
    [ "created_at", "home_page_section_id", "id", "link", "name", "position", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "home_page_section" ]
  end
end
