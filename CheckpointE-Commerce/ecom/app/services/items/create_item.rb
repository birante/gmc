# frozen_string_literal: true

module Items
  # Service de création d'un produit avec vérification des limites
  # Pattern Command / Use Case
  #
  # Usage:
  #   service = Items::CreateItem.new(shop: shop, params: params)
  #   result = service.call
  #   if result.success?
  #     # produit créé
  #   else
  #     # gérer les erreurs
  #   end
  class CreateItem
    Result = Struct.new(:success?, :item, :errors, keyword_init: true)

    def initialize(shop:, params:)
      @shop = shop
      @params = params
      @errors = []
    end

    def call
      Rails.logger.info("🏷️ [Items::CreateItem] Création produit - shop_id: #{@shop.id}")

      # Vérification des limites via capabilities
      unless @shop.capabilities.can_create_product?(@shop.items_count)
        error_message = build_limit_error_message
        @errors << error_message
        Rails.logger.warn("⚠️ [Items::CreateItem] Limite atteinte - shop_id: #{@shop.id}")
        return Result.new(success?: false, item: nil, errors: @errors)
      end

      # Création du produit
      @item = @shop.items.build(@params)

      if @item.save
        Rails.logger.info("✅ [Items::CreateItem] Produit créé - item_id: #{@item.id}")
        Result.new(success?: true, item: @item, errors: [])
      else
        @errors.concat(@item.errors.full_messages)
        Rails.logger.warn("⚠️ [Items::CreateItem] Échec création - erreurs: #{@errors.join(', ')}")
        Result.new(success?: false, item: @item, errors: @errors)
      end
    end

    private

    attr_reader :shop, :params

    def build_limit_error_message
      max = @shop.capabilities.max_products
      if max.nil?
        I18n.t("services.items.create_item.limit_reached_unlimited")
      else
        I18n.t("services.items.create_item.limit_reached_with_max", max: max, current: @shop.items_count)
      end
    end
  end
end
