class Tag < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: %i[slugged history]

  has_many :post_tags, dependent: :destroy
  has_many :posts, through: :post_tags

  validates :name, presence: true, uniqueness: true, length: { maximum: 50 }

  def self.ransackable_attributes(_ = nil); %w[id name slug]; end
  def self.ransackable_associations(_ = nil); %w[posts]; end
end
