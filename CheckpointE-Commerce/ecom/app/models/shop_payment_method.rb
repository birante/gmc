class ShopPaymentMethod < ApplicationRecord
  belongs_to :shop
  belongs_to :payment_method

  def self.ransackable_attributes(auth_object = nil)
    [ "id", "shop_id", "payment_method_id", "is_active", "created_at", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "shop", "payment_method" ]
  end
end
