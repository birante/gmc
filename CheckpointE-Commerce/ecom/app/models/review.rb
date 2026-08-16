class Review < ApplicationRecord
  belongs_to :user
  belongs_to :item
  belongs_to :order_item, optional: true

  # Active Storage pour les photos d'avis
  has_many_attached :images

  STATUSES = %w[pending approved rejected].freeze

  enum :status, STATUSES

  validates :rating, presence: true, inclusion: { in: 1..5 }
  validates :comment, length: { maximum: 2000 }
  validates :status, inclusion: { in: STATUSES }
  validates :user_id, uniqueness: { scope: :item_id, message: "a déjà laissé un avis pour ce produit" }

  scope :approved, -> { where(status: "approved") }
  scope :pending, -> { where(status: "pending") }
  scope :rejected, -> { where(status: "rejected") }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_rating, ->(rating) { where(rating: rating) }

  default_scope { order(created_at: :desc) }

  # Callbacks
  after_create :update_item_average_rating
  after_update :update_item_average_rating, if: -> { saved_change_to_rating? || saved_change_to_status? }
  after_destroy :update_item_average_rating

  def approved?
    status == "approved"
  end

  def pending?
    status == "pending"
  end

  def rejected?
    status == "rejected"
  end

  # Vérifie si l'utilisateur peut modifier l'avis
  def can_be_edited_by?(user)
    self.user == user && created_at > 7.days.ago
  end

  # Incrémente le compteur de "utile"
  def mark_as_helpful!
    increment!(:helpful_count)
  end

  private

  def update_item_average_rating
    # Mettre à jour la note moyenne du produit basée sur les avis approuvés
    approved_reviews = item.reviews.approved
    if approved_reviews.any?
      average_rating = approved_reviews.average(:rating)&.round(2)
      if item.respond_to?(:average_rating)
        item.update_column(:average_rating, average_rating)
        Rails.logger.info("✅ [Review] Note moyenne mise à jour - item_id: #{item_id}, note: #{average_rating}, nb_avis: #{approved_reviews.count}")
      end
    else
      # Pas d'avis approuvés, mettre la note moyenne à nil
      if item.respond_to?(:average_rating)
        item.update_column(:average_rating, nil)
      end
    end
  rescue => e
    Rails.logger.error("❌ [Review] Erreur mise à jour note moyenne - review_id: #{id}, item_id: #{item_id}, erreur: #{e.message}")
    Rails.logger.error(e.backtrace.first(5).join("\n"))
  end

  public

  def self.ransackable_attributes(auth_object = nil)
    [ "comment", "created_at", "helpful_count", "id", "item_id", "order_item_id", "rating", "status", "updated_at", "user_id" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "item", "order_item", "user" ]
  end
end
