class ShopSocialLink < ApplicationRecord
  belongs_to :shop
  belongs_to :social_platform

  def self.ransackable_attributes(auth_object = nil)
    [ "created_at", "id", "shop_id", "social_platform_id", "updated_at", "url" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "shop", "social_platform" ]
  end
end
