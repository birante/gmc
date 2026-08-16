class Address < ApplicationRecord
  extend FriendlyId
  friendly_id :slug_candidates, use: :slugged

  belongs_to :user
  belongs_to :delivery_zone, optional: true

  # Seul street_address est obligatoire
  validates :street_address, presence: true

  before_save :ensure_single_default, if: :is_default?
  after_create :log_address_creation
  after_update :log_default_change, if: :saved_change_to_is_default?

  # Retourne la zone de livraison (relation ou calculée)
  def calculated_delivery_zone
    # Si une zone est déjà assignée, on la retourne
    return super if delivery_zone_id.present?

    # Sinon, on calcule basé sur les coordonnées si disponibles
    return nil unless latitude.present? && longitude.present?
    DeliveryZone.find_by_coordinates(latitude, longitude)
  end

  def slug_candidates
    [
      [ :city, :id ],
      [ :city, :user_id, :id ]
    ]
  end

  def should_generate_new_friendly_id?
    slug.blank?
  end

  private

  def ensure_single_default
    Rails.logger.info("⭐ [Address] Définition adresse par défaut - address_id: #{id}, user_id: #{user_id}")
    Address.where(user_id: user_id, is_default: true)
           .where.not(id: id)
           .update_all(is_default: false)
  end

  def log_address_creation
    Rails.logger.info("📝 [Address] Adresse créée - address_id: #{id}, user_id: #{user_id}, ville: #{city}, par_défaut: #{is_default}")
  end

  def log_default_change
    Rails.logger.info("✏️ [Address] Changement statut par défaut - address_id: #{id}, nouveau_statut: #{is_default}")
  end

  public

  def self.ransackable_attributes(auth_object = nil)
    [ "id", "user_id", "delivery_zone_id", "street_address", "city", "postal_code", "country", "additional_info", "is_default", "latitude", "longitude", "created_at", "updated_at", "slug" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "user", "delivery_zone" ]
  end
end
