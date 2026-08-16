class ShopColor < ApplicationRecord
  HEX_FORMAT = /\A#\h{6}\z/

  # Palette de démarrage assignée à toute nouvelle boutique. Couvre les
  # couleurs les plus courantes dans le e-commerce local. Le vendeur peut
  # ensuite éditer, archiver ou compléter à volonté.
  DEFAULT_STARTER_PALETTE = [
    { name: "Noir",       hex_code: "#000000" },
    { name: "Blanc",      hex_code: "#FFFFFF" },
    { name: "Rouge",      hex_code: "#DC2626" },
    { name: "Bleu",       hex_code: "#1D4ED8" },
    { name: "Bleu marine", hex_code: "#0F172A" },
    { name: "Vert",       hex_code: "#16A34A" },
    { name: "Jaune",      hex_code: "#FACC15" },
    { name: "Orange",     hex_code: "#F97316" },
    { name: "Rose",       hex_code: "#EC4899" },
    { name: "Violet",     hex_code: "#7C3AED" },
    { name: "Gris",       hex_code: "#6B7280" },
    { name: "Beige",      hex_code: "#E7D7B5" },
    { name: "Marron",     hex_code: "#78350F" },
    { name: "Or",         hex_code: "#D4AF37" }
  ].freeze

  belongs_to :shop
  has_many :attribute_values, dependent: :nullify

  validates :name, presence: true, length: { maximum: 60 }
  validates :hex_code, presence: true, format: { with: HEX_FORMAT, message: "doit être au format #RRGGBB" }
  validates :name, uniqueness: { scope: :shop_id, conditions: -> { where(archived_at: nil) }, case_sensitive: false }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  before_validation :normalize_hex_code
  before_validation :assign_default_position, on: :create

  scope :active, -> { where(archived_at: nil) }
  scope :archived, -> { where.not(archived_at: nil) }
  scope :ordered, -> { order(:position, :id) }

  def archived?
    archived_at.present?
  end

  def archive!
    update!(archived_at: Time.current) unless archived?
  end

  def unarchive!
    update!(archived_at: nil) if archived?
  end

  private

  def normalize_hex_code
    return if hex_code.blank?
    self.hex_code = hex_code.strip
    self.hex_code = "##{hex_code}" unless hex_code.start_with?("#")
    self.hex_code = hex_code.downcase
  end

  def assign_default_position
    return if position.present? && position.positive?
    max_position = shop&.shop_colors&.maximum(:position) || 0
    self.position = max_position + 1
  end
end
