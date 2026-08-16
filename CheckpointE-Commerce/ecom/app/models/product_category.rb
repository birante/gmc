class ProductCategory < ApplicationRecord
  extend FriendlyId
  include PublicLink

  friendly_id :name, use: :slugged

  # Attachment pour l'icône de la catégorie
  has_one_attached :icon

  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true
  validates :description, presence: false
  validates :is_active, inclusion: { in: [ true, false ] }

  has_many :sub_categories, class_name: "ProductSubCategory", dependent: :destroy

  before_create :set_default_position
  after_create :log_category_creation

  # S'assurer que les requêtes sont toujours triées par la position
  default_scope { order(position: :asc, name: :asc) }

  private

  def set_default_position
    # Trouve la position maximale actuelle. Utilise 0 si MAX(position) est NULL (première catégorie).
    max_position = ProductCategory.maximum(:position) || 0

    # Assigne la position suivante.
    self.position = max_position + 1
  end

  def log_category_creation
    Rails.logger.info("🏷️ [ProductCategory] Catégorie créée - category_id: #{id}, nom: #{name}, position: #{position}")
  end

  def self.ransackable_attributes(auth_object = nil)
    [ "created_at", "description", "id", "is_active", "name", "position", "slug", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "sub_categories" ]
  end

  def public_url
    Rails.application.routes.url_helpers.client_category_url(
      slug: friendly_id,
      host: Rails.configuration.action_controller.asset_host || Rails.application.config.app_host || "localhost:3000"
    )
  rescue
    nil
  end
end
