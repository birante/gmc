class ShopSector < ApplicationRecord
  belongs_to :shop
  belongs_to :sector

  def self.ransackable_attributes(auth_object = nil)
    [ "created_at", "id", "sector_id", "shop_id", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "shop", "sector" ]
  end
end
