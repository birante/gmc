class Sector < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  has_many :shops, class_name: "ShopSector", dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true
  validates :description, presence: false
  validates :position, presence: true, uniqueness: true, numericality: { greater_than: 0 }
  validates :is_active, inclusion: { in: [ true, false ] }

  scope :ordered, -> { order(:position) }
  scope :active, -> { where(is_active: true) }

  before_validation :set_position_if_blank, on: :create

  private

  def set_position_if_blank
    return if position.present?

    # Récupère la position maximale et ajoute 1
    max_position = Sector.maximum(:position) || 0
    self.position = max_position + 1
  end

  def self.ransackable_attributes(auth_object = nil)
    [ "created_at", "description", "id", "is_active", "name", "position", "slug", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "shops" ]
  end
end
