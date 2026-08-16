class Plan < ApplicationRecord
  SUPPORT_CONTACT_PHONE = ENV.fetch("aa_SUPPORT_PHONE", "+221 77 881 83 83")

  has_many :plan_rules, dependent: :destroy
  has_many :rules, through: :plan_rules
  has_many :subscriptions, dependent: :destroy
  has_many :shops, through: :subscriptions

  validates :code, presence: true, uniqueness: true
  validates :name, presence: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :billing_period_months, numericality: { greater_than: 0 }, allow_nil: true

  scope :active, -> { where(is_active: true) }
  scope :custom, -> { where(is_custom: true) }
  scope :standard, -> { where(is_custom: false) }

  # Retourne le prix formaté selon le modèle de facturation
  def formatted_price
    if price.present? && billing_period_months.present?
      "#{price.to_i} FCFA / #{billing_period_months} mois"
    elsif price.present?
      "#{price.to_i} FCFA"
    else
      "0 FCFA"
    end
  end

  def requires_contact?
    is_custom?
  end

  def purchasable_online?
    !requires_contact?
  end

  def self.support_contact_phone
    SUPPORT_CONTACT_PHONE
  end

  def self.support_contact_phone_href
    "tel:#{support_contact_phone.gsub(/[^\d+]/, "")}"
  end

  def self.ransackable_attributes(auth_object = nil)
    [ "code", "created_at", "description", "id", "id_value", "is_active", "is_custom", "name", "updated_at", "price", "billing_period_months" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "plan_rules", "rules", "subscriptions", "shops" ]
  end
end
