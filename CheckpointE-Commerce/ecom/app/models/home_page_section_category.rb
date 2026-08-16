class HomePageSectionCategory < ApplicationRecord
  belongs_to :home_page_section
  belongs_to :product_category
  belongs_to :product_sub_category

  def self.ransackable_attributes(auth_object = nil)
    [ "created_at", "home_page_section_id", "id", "position", "product_category_id", "product_sub_category_id", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "home_page_section", "product_category", "product_sub_category" ]
  end
end
