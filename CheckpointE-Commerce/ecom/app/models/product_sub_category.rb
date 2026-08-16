class ProductSubCategory < ApplicationRecord
  extend FriendlyId
  include PublicLink

  friendly_id :name, use: :slugged

  belongs_to :product_category

  # Attachment pour l'icône de la sous-catégorie
  has_one_attached :icon

  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true
  validates :description, presence: false
  validates :is_active, inclusion: { in: [ true, false ] }

  before_create :set_default_position
  after_create :log_sub_category_creation

  # S'assurer que les requêtes sont toujours triées par la position
  default_scope { order(position: :asc, name: :asc) }

  def public_url
    Rails.application.routes.url_helpers.client_sub_category_url(
      category_slug: product_category.friendly_id,
      slug: friendly_id,
      host: Rails.configuration.action_controller.asset_host || Rails.application.config.app_host || "localhost:3000"
    )
  rescue
    nil
  end

  def self.ransackable_attributes(auth_object = nil)
    [ "created_at", "description", "id", "is_active", "name", "position", "product_category_id", "slug", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "product_category" ]
  end

  private

  def set_default_position
    # Trouve la position maximale UNIQUEMENT pour la catégorie parente (le scope est essentiel)
    max_position = ProductSubCategory
                     .where(product_category_id: self.product_category_id)
                     .maximum(:position) || 0

    # Assigne la position suivante dans ce groupe.
    self.position = max_position + 1
  end

  def log_sub_category_creation
    Rails.logger.info("🏷️ [ProductSubCategory] Sous-catégorie créée - sub_category_id: #{id}, nom: #{name}, category_id: #{product_category_id}, position: #{position}")
  end
end
