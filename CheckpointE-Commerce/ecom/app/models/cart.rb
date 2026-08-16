class Cart < ApplicationRecord
  extend FriendlyId
  friendly_id :slug_candidates, use: :slugged

  belongs_to :user, optional: true
  has_many :cart_items, -> {
    includes(
      :item_variant,
      item: [
        :variants,
        :currency,
        { main_image_attachment: :blob },
        { images_attachments: :blob }
      ]
    )
  }, dependent: :destroy
  has_many :items, through: :cart_items

  STATUSES = %w[active completed abandoned].freeze

  validates :status, inclusion: { in: STATUSES }

  scope :active, -> { where(status: "active") }

  # Callbacks pour logging
  after_create :log_creation
  after_update :log_status_change, if: -> { saved_change_to_status? }

  def total_amount
    cart_items.sum(&:total_price)
  end

  def total_items_count
    cart_items.sum(:quantity)
  end

  def slug_candidates
    [
      [ user_id || "guest", :id ],
      [ user_id || "guest", :status, :id ]
    ]
  end

  def guest?
    user_id.nil?
  end

  def cash_on_delivery_blocked?
    cart_items.joins(:item).where(items: { cash_on_delivery_disabled: true }).exists?
  end

  # nil = aucune restriction par produit ; sinon intersection des listes autorisées
  def effective_allowed_payment_codes
    sets = []
    cart_items.includes(:item).each do |ci|
      item = ci.item
      next unless item&.restricts_checkout_payment_codes?

      sets << item.allowed_payment_code_list.to_set
    end
    return nil if sets.empty?

    sets.reduce(:&).to_a
  end

  def should_generate_new_friendly_id?
    slug.blank?
  end

  def self.ransackable_attributes(auth_object = nil)
    [ "id", "user_id", "status", "slug", "created_at", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "user", "cart_items" ]
  end

  private

  def log_creation
    user_info = user_id ? "user_id: #{user_id}" : "invité"
    Rails.logger.info("🛒 [Cart] Panier créé - cart_id: #{id}, #{user_info}, statut: #{status}")
  end

  def log_status_change
    old_status, new_status = saved_change_to_status
    user_info = user_id ? "user_id: #{user_id}" : "invité"
    Rails.logger.info("✏️ [Cart] Changement statut panier - cart_id: #{id}, #{user_info}, ancien_statut: #{old_status}, nouveau_statut: #{new_status}")
  end
end
