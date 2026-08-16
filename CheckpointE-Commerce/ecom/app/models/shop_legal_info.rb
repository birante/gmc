class ShopLegalInfo < ApplicationRecord
  belongs_to :shop

  def self.ransackable_attributes(auth_object = nil)
    [ "created_at", "id", "shop_id", "updated_at", "legal_form", "rc_number", "ninea_number" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "shop" ]
  end
end
