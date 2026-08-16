class HomePageSectionSetting < ApplicationRecord
  belongs_to :home_page_section

  def self.ransackable_attributes(auth_object = nil)
    [ "created_at", "home_page_section_id", "id", "key", "updated_at", "value" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "home_page_section" ]
  end
end
