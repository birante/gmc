class Vendors::EmployeesController < Vendors::BaseController
  before_action :set_employee, only: [ :edit, :update, :destroy, :toggle_status ]

  def index
    @employees = current_vendor.employees.includes(shops: [], employee_shops: :shop).order(created_at: :desc)
  end

  def new
    @employee = current_vendor.employees.build
    @shops = current_vendor.shops.order(:name)
  end

  def create
    service = Employees::EmployeeCreationService.new(
      vendor: current_vendor,
      params: employee_params
    )
    result = service.call

    if result.success?
      redirect_to vendors_employees_path, notice: t("vendors.employees.messages.created")
    else
      @employee = result.employee || current_vendor.employees.build(employee_params.except(:shop_ids))
      @shops = current_vendor.shops.order(:name)
      flash.now[:alert] = result.errors.first if result.errors.any?
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @shops = current_vendor.shops.order(:name)
    @employee.employee_shops.load if @employee.persisted?
  end

  def update
    service = Employees::EmployeeUpdateService.new(
      employee: @employee,
      params: employee_params
    )
    result = service.call

    if result.success?
      redirect_to vendors_employees_path, notice: t("vendors.employees.messages.updated")
    else
      @shops = current_vendor.shops.order(:name)
      flash.now[:alert] = result.errors.first if result.errors.any?
      render :edit, status: :unprocessable_entity
    end
  end

  def toggle_status
    old_status = @employee.status
    @employee.update(status: @employee.active? ? :inactive : :active)
    Rails.logger.info("[Vendors::EmployeesController] Toggle statut collaborateur - employee_id: #{@employee.id}, ancien_statut: #{old_status}, nouveau_statut: #{@employee.status}")
    redirect_to vendors_employees_path, notice: t("vendors.employees.messages.status_updated")
  end

  def destroy
    Rails.logger.info("[Vendors::EmployeesController] Suppression collaborateur - employee_id: #{@employee.id}, vendor_id: #{current_vendor.id}")
    @employee.destroy
    redirect_to vendors_employees_path, notice: t("vendors.employees.messages.deleted")
  end

  private

  def set_employee
    @employee = current_vendor.employees.find(params[:id])
  end

  def employee_params
    # Note: :role is permitted because vendors should be able to assign roles to their employees.
    # Role values are validated by the Employee model against Employee::ROLES.
    # :status is excluded from mass assignment - use toggle_status action instead.
    params.require(:employee).permit( # brakeman:ignore:MassAssignment
      :email, :password, :password_confirmation,
      :first_name, :last_name,
      :country_code, :phone_number,
      :role,
      shop_ids: []
    )
  end
end
