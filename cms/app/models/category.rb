class Category < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: %i[slugged history]

  belongs_to :parent, class_name: "Category", optional: true
  has_many :children, class_name: "Category", foreign_key: :parent_id, dependent: :nullify
  has_many :posts, dependent: :nullify

  validates :name, presence: true, length: { maximum: 100 }

  scope :roots, -> { where(parent_id: nil) }

  def self.ransackable_attributes(_ = nil); %w[id name slug active display_order]; end
  def self.ransackable_associations(_ = nil); %w[posts children parent]; end
end
