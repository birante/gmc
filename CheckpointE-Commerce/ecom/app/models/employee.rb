class Employee < ApplicationRecord
  has_secure_password

  belongs_to :vendor
  has_many :sessions, as: :sessionable, dependent: :destroy
  has_many :employee_shops, dependent: :destroy
  has_many :shops, through: :employee_shops

  # Callbacks
  after_create :log_creation
  after_update :log_update, if: :saved_changes?

  # Statut du compte (aligné sur Vendor#status). Les collaborateurs sont créés
  # par le vendeur, donc le statut par défaut est :active (pas de vérification OTP).
  enum :status, { pending: "pending", active: "active", suspended: "suspended", inactive: "inactive" }, default: :active

  # Rôles disponibles
  ROLES = {
    manager: "manager",           # Gestionnaire - accès complet à la boutique
    cashier: "cashier",           # Caissier - gère les ventes et commandes
    stock_manager: "stock_manager", # Gestionnaire de stock - gère l'inventaire
    delivery: "delivery"          # Livreur - accès aux commandes à livrer
  }.freeze

  # Validations
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :role, presence: true, inclusion: { in: ROLES.values }
  validates :phone_number, presence: true
  validates :country_code, presence: true

  # Scopes (:active / :inactive / :pending / :suspended sont fournis par l'enum status)
  scope :by_role, ->(role) { where(role: role) }
  scope :for_shop, ->(shop_id) { joins(:employee_shops).where(employee_shops: { shop_id: shop_id }) }

  # Méthodes
  def full_name
    "#{first_name} #{last_name}"
  end

  def formatted_phone_number
    "+#{country_code} #{phone_number}"
  end

  # active? / inactive? / pending? / suspended? sont fournis par l'enum status

  # Permissions selon le rôle
  def can_manage_items?
    manager? || stock_manager?
  end

  def can_manage_orders?
    manager? || cashier?
  end

  def can_manage_inventory?
    manager? || stock_manager?
  end

  def can_view_reports?
    manager?
  end

  def can_manage_employees?
    false # Seul le vendor peut gérer les employés
  end

  # Vérification des rôles
  def manager?
    role == ROLES[:manager]
  end

  def cashier?
    role == ROLES[:cashier]
  end

  def stock_manager?
    role == ROLES[:stock_manager]
  end

  def delivery?
    role == ROLES[:delivery]
  end

  def role_name
    case role
    when ROLES[:manager]
      "Gestionnaire"
    when ROLES[:cashier]
      "Caissier"
    when ROLES[:stock_manager]
      "Gestionnaire de stock"
    when ROLES[:delivery]
      "Livreur"
    else
      role
    end
  end

  # Boutique principale de l'employé
  def primary_shop
    shops.joins(:employee_shops).find_by(employee_shops: { is_primary: true })
  end

  # Liste des noms de boutiques
  def shop_names
    shops.pluck(:name).join(", ")
  end

  private

  def log_creation
    Rails.logger.info("👨‍💼 [Employee] Employé créé - employee_id: #{id}, email: #{email}, rôle: #{role_name}, vendor_id: #{vendor_id}, nom: #{full_name}")
  end

  def log_update
    changes_summary = saved_changes.except("updated_at", "password_digest").keys.join(", ")
    if changes_summary.present?
      status_change = saved_changes["status"] ? " (statut: #{saved_changes['status'][0]} → #{saved_changes['status'][1]})" : ""
      Rails.logger.info("✏️ [Employee] Employé mis à jour - employee_id: #{id}, champs modifiés: #{changes_summary}#{status_change}")
    end
  end

  public

  def self.ransackable_attributes(auth_object = nil)
    [ "id", "vendor_id", "email", "first_name", "last_name", "phone_number", "country_code", "role", "status", "created_at", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "vendor", "sessions", "employee_shops", "shops" ]
  end
end
