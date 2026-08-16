class LocalShopBanner < ApplicationRecord
  belongs_to :home_page_section

  has_one_attached :image

  scope :active, -> { where(active: true) }

  def self.ransackable_attributes(auth_object = nil)
    [ "active", "created_at", "home_page_section_id", "id", "link", "name", "position", "slug", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "home_page_section" ]
  end
end
