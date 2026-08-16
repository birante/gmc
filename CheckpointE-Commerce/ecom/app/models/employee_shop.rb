class EmployeeShop < ApplicationRecord
  belongs_to :employee
  belongs_to :shop

  # Validations
  validates :employee_id, uniqueness: { scope: :shop_id, message: "est déjà associé à cette boutique" }
  validates :shop_id, presence: true
  validates :employee_id, presence: true

  # Callbacks
  before_save :ensure_single_primary_shop, if: :is_primary?
  after_create :log_association_creation

  private

  # S'assurer qu'un employé n'a qu'une seule boutique principale
  def ensure_single_primary_shop
    Rails.logger.info("🔗 [EmployeeShop] Définition boutique principale - employee_id: #{employee_id}, shop_id: #{shop_id}")
    EmployeeShop.where(employee_id: employee_id, is_primary: true)
                .where.not(id: id)
                .update_all(is_primary: false)
  end

  def log_association_creation
    Rails.logger.info("📝 [EmployeeShop] Association créée - employee_id: #{employee_id}, shop_id: #{shop_id}, principale: #{is_primary}")
  end

  def self.ransackable_attributes(auth_object = nil)
    [ "id", "employee_id", "shop_id", "is_primary", "created_at", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "employee", "shop" ]
  end
end
