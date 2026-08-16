class AddOn < ApplicationRecord
  has_many :shop_add_ons, dependent: :destroy
  has_many :shops, through: :shop_add_ons

  validates :code, presence: true, uniqueness: true
  validates :name, presence: true

  scope :active, -> { where(is_active: true) }

  def self.ransackable_attributes(auth_object = nil)
    [ "code", "created_at", "description", "id", "id_value", "is_active", "name", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "shop_add_ons", "shops" ]
  end
end
