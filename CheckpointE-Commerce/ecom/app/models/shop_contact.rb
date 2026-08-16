class ShopContact < ApplicationRecord
  belongs_to :shop

  before_validation :set_default_country_code, on: :create

  private

  def set_default_country_code
    self.country_code = "221" if self.country_code.blank?
  end

  def self.ransackable_attributes(auth_object = nil)
    [ "country_code", "created_at", "id", "is_whatsapp", "phone_number", "shop_id", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "shop" ]
  end
end
