class ShopBanner < ApplicationRecord
  belongs_to :shop

  has_one_attached :image

  validates :position, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :title, presence: true

  default_scope { order(position: :asc) }

  def self.ransackable_attributes(auth_object = nil)
    [ "created_at", "cta_link", "cta_text", "id", "position", "shop_id", "title", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "shop" ]
  end
end
