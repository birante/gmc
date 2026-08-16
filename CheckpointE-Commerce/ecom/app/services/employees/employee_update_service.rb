# frozen_string_literal: true

module Employees
  # Service de mise à jour d'un collaborateur
  #
  # Usage:
  #   service = Employees::EmployeeUpdateService.new(employee: employee, params: params)
  #   result = service.call
  #   if result.success?
  #     # collaborateur mis à jour
  #   else
  #     # gérer les erreurs
  #   end
  class EmployeeUpdateService
    Result = Struct.new(:success?, :employee, :errors, keyword_init: true)

    def initialize(employee:, params:)
      @employee = employee
      @params = params
      @errors = []
    end

    def call
      Rails.logger.info("[Employees::EmployeeUpdateService] Mise à jour collaborateur - employee_id: #{@employee.id}")

      # Mettre à jour les informations de base
      if @employee.update(employee_attributes)
        update_shop_associations
        Rails.logger.info("[Employees::EmployeeUpdateService] Collaborateur mis à jour - employee_id: #{@employee.id}")
        Result.new(success?: true, employee: @employee, errors: [])
      else
        @errors.concat(@employee.errors.full_messages)
        Rails.logger.warn("[Employees::EmployeeUpdateService] Échec mise à jour - erreurs: #{@errors.join(', ')}")
        Result.new(success?: false, employee: @employee, errors: @errors)
      end
    end

    private

    attr_reader :employee, :params

    def employee_attributes
      @params.except(:shop_ids)
    end

    def shop_ids
      @shop_ids ||= Array(@params[:shop_ids]).reject(&:blank?)
    end

    def update_shop_associations
      return if shop_ids.empty?

      # Supprimer les anciennes associations
      @employee.employee_shops.destroy_all

      # Créer les nouvelles associations
      shop_ids.each_with_index do |shop_id, index|
        @employee.employee_shops.create!(
          shop_id: shop_id,
          is_primary: index == 0
        )
      end

      Rails.logger.info("[Employees::EmployeeUpdateService] #{shop_ids.count} boutique(s) associée(s) - employee_id: #{@employee.id}")
    end
  end
end
