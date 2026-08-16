# frozen_string_literal: true

module Rules
  # Service de résolution des règles avec priorité
  # Hiérarchie : ShopRule > PlanRule > Rule.default_value
  #
  # Usage:
  #   resolver = Rules::RuleResolver.new(shop)
  #   max_products = resolver.value("max_products") # nil = illimité
  #   enabled = resolver.enabled?("order_management") # true/false
  class RuleResolver
    def initialize(shop)
      @shop = shop
    end

    # Retourne la valeur d'une règle selon la hiérarchie de priorité
    # @param code [String] Le code de la règle (ex: "max_products")
    # @return [Object, nil] La valeur de la règle (nil = illimité pour les entiers)
    def value(code)
      rule = Rule.find_by(code: code, is_active: true)
      return nil unless rule

      # Priorité : ShopRule > PlanRule > Rule.default_value
      shop_override(rule) ||
        plan_override(rule) ||
        rule.default_value
    end

    # Vérifie si une fonctionnalité est activée
    # @param code [String] Le code de la règle
    # @return [Boolean] true si activé, false sinon
    def enabled?(code)
      value = value(code)
      value != false && value.present?
    end

    # Retourne toutes les règles résolues pour cette boutique
    # @return [Hash] Hash avec les codes de règles comme clés
    def all_rules
      Rule.active.each_with_object({}) do |rule, hash|
        hash[rule.code] = value(rule.code)
      end
    end

    private

    attr_reader :shop

    # Récupère l'override boutique (priorité la plus haute)
    def shop_override(rule)
      shop_rule = shop.shop_rules.find_by(rule: rule, is_active: true)
      return nil unless shop_rule

      shop_rule.value
    end

    # Récupère la valeur du plan via l'abonnement actif
    def plan_override(rule)
      subscription = shop.current_subscription
      return nil unless subscription

      plan_rule = subscription.plan
                              .plan_rules
                              .find_by(rule: rule, is_active: true)
      return nil unless plan_rule

      plan_rule.value
    end
  end
end
