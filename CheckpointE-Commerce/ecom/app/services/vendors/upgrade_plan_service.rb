# frozen_string_literal: true

module Vendors
  class UpgradePlanService
    Result = Struct.new(:success?, :subscription, :errors, keyword_init: true)

    def initialize(shop:, new_plan:)
      @shop = shop
      @new_plan = new_plan
      @errors = []
    end

    def call
      validate_plan
      return Result.new(success?: false, errors: @errors) unless @errors.empty?

      ActiveRecord::Base.transaction do
        # Annuler l'ancienne subscription si elle existe
        cancel_current_subscription

        # Créer la nouvelle subscription
        @subscription = Subscription.create!(
          shop: @shop,
          plan: @new_plan,
          status: "active",
          started_at: Time.current,
          ends_at: 1.year.from_now
        )

        Rails.logger.info("[Vendors::UpgradePlanService] Plan mis a niveau - shop_id: #{@shop.id}, ancien_plan: #{@old_plan&.code}, nouveau_plan: #{@new_plan.code}")

        Result.new(success?: true, subscription: @subscription)
      end
    rescue StandardError => e
      Rails.logger.error("[Vendors::UpgradePlanService] Erreur lors de la mise a niveau - shop_id: #{@shop.id}, erreur: #{e.message}")
      @errors << e.message
      Result.new(success?: false, errors: @errors)
    end

    private

    def validate_plan
      @errors << I18n.t("vendors.plans.invalid_plan") unless @new_plan&.is_active?
      @errors << I18n.t("vendors.plans.shop_required") unless @shop
    end

    def cancel_current_subscription
      current_subscription = @shop.current_subscription
      return unless current_subscription

      @old_plan = current_subscription.plan
      current_subscription.update!(status: "cancelled")
      Rails.logger.info("[Vendors::UpgradePlanService] Ancienne subscription annulee - subscription_id: #{current_subscription.id}")
    end
  end
end
