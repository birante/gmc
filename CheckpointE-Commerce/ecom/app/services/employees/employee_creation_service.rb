# frozen_string_literal: true

module Employees
  # Service de création d'un collaborateur avec vérification des limites
  #
  # Usage:
  #   service = Employees::EmployeeCreationService.new(vendor: vendor, params: params)
  #   result = service.call
  #   if result.success?
  #     # collaborateur créé
  #   else
  #     # gérer les erreurs
  #   end
  class EmployeeCreationService
    Result = Struct.new(:success?, :employee, :errors, keyword_init: true)

    def initialize(vendor:, params:)
      @vendor = vendor
      @params = params
      @errors = []
    end

    def call
      Rails.logger.info("[Employees::EmployeeCreationService] Création collaborateur - vendor_id: #{@vendor.id}, email: #{@params[:email]}")

      # Vérifier les limites pour chaque boutique sélectionnée
      validation_result = validate_employee_limits
      return validation_result unless validation_result.nil?

      # Créer le collaborateur
      @employee = @vendor.employees.build(employee_attributes)

      if @employee.save
        associate_shops
        Rails.logger.info("[Employees::EmployeeCreationService] Collaborateur créé - employee_id: #{@employee.id}, vendor_id: #{@vendor.id}")
        Result.new(success?: true, employee: @employee, errors: [])
      else
        @errors.concat(@employee.errors.full_messages)
        Rails.logger.warn("[Employees::EmployeeCreationService] Échec création - erreurs: #{@errors.join(', ')}")
        Result.new(success?: false, employee: @employee, errors: @errors)
      end
    end

    private

    attr_reader :vendor, :params

    def employee_attributes
      @params.except(:shop_ids)
    end

    def shop_ids
      @shop_ids ||= Array(@params[:shop_ids]).reject(&:blank?)
    end

    def validate_employee_limits
      return nil if shop_ids.empty?

      shop_ids.each do |shop_id|
        shop = @vendor.shops.find_by(id: shop_id)
        next unless shop

        current_employee_count = shop.employees.active.count

        unless shop.capabilities.can_add_employee?(current_employee_count)
          max = shop.capabilities.max_employees
          error_message = build_limit_error_message(max, current_employee_count, shop.name)
          Rails.logger.warn("[Employees::EmployeeCreationService] Limite atteinte - shop_id: #{shop.id}, max: #{max}, current: #{current_employee_count}")
          return Result.new(success?: false, employee: nil, errors: [ error_message ])
        end
      end

      nil
    end

    def build_limit_error_message(max, current, shop_name)
      if max.nil?
        I18n.t("services.employees.limit_reached_unlimited")
      else
        I18n.t("services.employees.limit_reached_with_max", max: max, current: current, shop_name: shop_name)
      end
    end

    def associate_shops
      return if shop_ids.empty?

      shop_ids.each_with_index do |shop_id, index|
        @employee.employee_shops.create!(
          shop_id: shop_id,
          is_primary: index == 0 # La première est la principale
        )
      end

      Rails.logger.info("[Employees::EmployeeCreationService] #{shop_ids.count} boutique(s) associée(s) - employee_id: #{@employee.id}")
    end
  end
end
