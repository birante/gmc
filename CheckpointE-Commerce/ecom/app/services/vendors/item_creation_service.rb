# frozen_string_literal: true

module Vendors
  class ItemCreationService
    Result = Struct.new(:success?, :item, :errors, keyword_init: true)

    def initialize(shop:, params:, commit: nil)
      @shop = shop
      @params = params
      @commit = commit
      @errors = []
      @item_repository = ItemRepository.new
    end

    def call
      start_time = Time.current
      Rails.logger.info("🏷️ [Vendors::ItemCreationService] ========== CRÉATION PRODUIT ==========")
      Rails.logger.info("📋 [Vendors::ItemCreationService] Shop ID: #{@shop.id} | Shop: #{@shop.name}")
      Rails.logger.info("📝 [Vendors::ItemCreationService] Nom produit: #{@params[:name].presence || 'Vide'}")

      # Vérification des limites via capabilities
      current_items_count = @item_repository.count_for_shop(@shop)
      Rails.logger.info("📊 [Vendors::ItemCreationService] Produits existants: #{current_items_count}")

      unless @shop.capabilities.can_create_product?(current_items_count)
        max = @shop.capabilities.max_products
        error_message = if max.nil?
          I18n.t("services.vendors.item_creation.limit_reached_unlimited")
        else
          I18n.t("services.vendors.item_creation.limit_reached_with_max", max: max)
        end
        duration = (Time.current - start_time).round(3)
        Rails.logger.warn("⚠️ [Vendors::ItemCreationService] Limite atteinte après #{duration}s - Shop: #{@shop.id} | Max: #{max || 'illimité'} | Actuel: #{current_items_count}")
        return Result.new(success?: false, item: nil, errors: [ error_message ])
      end
      Rails.logger.info("✅ [Vendors::ItemCreationService] Quota disponible - Max: #{@shop.capabilities.max_products || 'illimité'}")

      prepare_start = Time.current
      attrs = prepare_attributes
      prepare_duration = (Time.current - prepare_start).round(3)
      Rails.logger.info("📊 [Vendors::ItemCreationService] Attributs préparés en #{prepare_duration}s - Variants: #{@variants_to_create&.count || 0}")

      create_start = Time.current
      @item = @item_repository.create_for_shop(@shop, attrs)
      create_duration = (Time.current - create_start).round(3)

      if @item.save
        variants_start = Time.current
        process_variants_with_combinations
        auto_generate_variants_from_attributes
        variants_duration = (Time.current - variants_start).round(3)
        Rails.logger.info("✅ [Vendors::ItemCreationService] Variants traitées en #{variants_duration}s - Count: #{@item.variants.count}")

        publish_start = Time.current
        handle_publish_option
        publish_duration = (Time.current - publish_start).round(3)
        Rails.logger.info("📢 [Vendors::ItemCreationService] Publication traitée en #{publish_duration}s - Commit: #{@commit}")

        ai_start = Time.current
        trigger_ai_enrichment
        ai_duration = (Time.current - ai_start).round(3)
        Rails.logger.info("🤖 [Vendors::ItemCreationService] AI trigger en #{ai_duration}s")

        total_duration = (Time.current - start_time).round(3)
        Rails.logger.info("✅ [Vendors::ItemCreationService] Produit créé avec succès en #{total_duration}s - Item ID: #{@item.id} | Variants: #{@item.variants.count}")
        Result.new(success?: true, item: @item, errors: [])
      else
        duration = (Time.current - start_time).round(3)
        Rails.logger.error("❌ [Vendors::ItemCreationService] Échec création après #{duration}s - #{@item.errors.full_messages.join(', ')}")
        Result.new(success?: false, item: @item, errors: @item.errors.full_messages)
      end
    rescue StandardError => e
      duration = (Time.current - start_time).round(3)
      Rails.logger.error("❌ [Vendors::ItemCreationService] EXCEPTION après #{duration}s - #{e.class}: #{e.message}")
      Rails.logger.error("❌ [Vendors::ItemCreationService] Backtrace: #{e.backtrace.first(5).join('\n')}")
      Result.new(success?: false, item: @item || nil, errors: [ e.message ])
    end

    private

    attr_reader :shop, :params

    def prepare_attributes
      Rails.logger.info("🚀 [Vendors::ItemCreationService] Préparation des attributs...")
      attrs = @params.to_h.dup

      # Séparer les variantes avec combination_data
      @variants_to_create = extract_variants_with_combinations(attrs)
      Rails.logger.info("🔗 [Vendors::ItemCreationService] Variants avec combinaisons: #{@variants_to_create.count}") if @variants_to_create.any?

      # Gérer les variantes normales
      normalize_variants_attributes(attrs)

      # Mapper les anciens champs vers les nouveaux
      map_legacy_fields(attrs)

      # Assigner le statut par défaut
      attrs["validation_status"] = "pending" unless attrs["validation_status"].present?

      # Initialiser le statut d'enrichissement IA
      attrs["ai_enrichment_status"] = "pending" unless attrs["ai_enrichment_status"].present?

      variants_count = attrs["variants_attributes"]&.count || 0
      Rails.logger.info("📊 [Vendors::ItemCreationService] Attributs préparés - Variants normales: #{variants_count} | Status: #{attrs['validation_status']}")
      attrs
    end

    def extract_variants_with_combinations(attrs)
      variants_with_combinations = []

      return variants_with_combinations unless attrs["variants_attributes"].present?

      attrs["variants_attributes"].each do |key, variant_attrs|
        if variant_attrs["combination_data"].present?
          variants_with_combinations << variant_attrs.dup
          variant_attrs["_destroy"] = "1"
        end
      end

      variants_with_combinations
    end

    def normalize_variants_attributes(attrs)
      return unless attrs["variants_attributes"].present?

      attrs["variants_attributes"].each do |key, variant_attrs|
        variant_attrs.delete("combination_data")

        # Si le prix est vide ou 0, utiliser le prix de base
        if variant_attrs["price"].blank? || variant_attrs["price"].to_f == 0
          variant_attrs["price"] = attrs["price"] || attrs["default_price"] || 0
        end
      end
    end

    def map_legacy_fields(attrs)
      # Si aucune variante n'est fournie, utiliser les champs legacy
      if attrs["variants_attributes"].blank? || attrs["variants_attributes"].empty?
        attrs["default_price"] = attrs["default_price"].presence || attrs["price"]
        attrs["default_stock_quantity"] = attrs["default_stock_quantity"].presence || attrs["stock_quantity"]
      end

      # Supprimer les anciens champs
      attrs.delete("price")
      attrs.delete("stock_quantity")
    end

    def process_variants_with_combinations
      return unless @variants_to_create&.any?

      Rails.logger.info("🔗 [Vendors::ItemCreationService] Traitement de #{@variants_to_create.count} variantes avec attributs...")
      VariantCreationService.new(@item).process_variants_with_attributes(@variants_to_create)
      Rails.logger.info("✅ [Vendors::ItemCreationService] Variantes avec attributs traitées")
    end

    # Génère automatiquement les variantes à partir des item_attributes si le
    # vendeur a défini des attributs (Couleur, Taille…) sans avoir explicitement
    # cliqué sur « Générer les combinaisons » avant de publier. Évite de se
    # retrouver avec un produit qui a 5 couleurs déclarées mais 1 seule
    # variante par défaut, incohérence visible côté client.
    def auto_generate_variants_from_attributes
      @item.reload
      return if @item.item_attributes.empty?
      return unless @item.variants.where(is_default: false).empty?

      Rails.logger.info("🎯 [Vendors::ItemCreationService] Auto-génération des variantes depuis les attributs (aucune combinaison explicite fournie)")
      default_variant = @item.variants.find_by(is_default: true)
      created = VariantGeneratorService.new(@item).generate_variants!(
        default_variant&.price,
        default_variant&.stock_quantity
      )
      if created.any? && default_variant
        # Le produit a maintenant de vraies variantes ; la variante par défaut
        # n'a plus de sens et bloquerait le sélecteur cross-attribut côté client.
        default_variant.destroy
      end
    end

    def handle_publish_option
      return unless @commit == "publish"

      Rails.logger.info("📢 [Vendors::ItemCreationService] Option publier reçue - plus de flag is_active sur Item")
    end

    def trigger_ai_enrichment
      return unless @item.shop.capabilities.ai_background_generation_enabled?

      Rails.logger.info("🤖 [Vendors::ItemCreationService] Déclenchement enrichissement IA - Item ID: #{@item.id}")
      ::ItemAIEnrichmentJob.perform_later(@item.id)
      Rails.logger.info("✅ [Vendors::ItemCreationService] Job AI enqueueé")
    end
  end
end
