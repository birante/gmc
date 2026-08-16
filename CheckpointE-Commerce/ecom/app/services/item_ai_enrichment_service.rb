# frozen_string_literal: true

# Service d'enrichissement de produits par Intelligence Artificielle
#
# Génère automatiquement du contenu optimisé pour un produit:
#   - Titre SEO-friendly
#   - Description marketing
#   - Meta description
#   - Tags/mots-clés
#
# Prérequis:
#   - capacities.ai_background_generation_enabled? doit être true
#   - Produit doit avoir au moins un nom de base
#
# Statuts:
#   - pending: En attente de traitement
#   - processing: Génération en cours
#   - completed: Génération réussie
#   - failed: Erreur lors de la génération
#
# Usage:
#   service = ItemAIEnrichmentService.new(item: @item)
#   result = service.call
#   if result.success?
#     puts "Titre généré: #{result.enriched_data[:title]}"
#   end
#
# @see Item
# @see Shops::Capabilities
class ItemAIEnrichmentService
  Result = Struct.new(:success?, :item, :enriched_data, :errors, keyword_init: true)

  AI_ENRICHMENT_STATUSES = {
    pending: "pending",
    processing: "processing",
    completed: "completed",
    failed: "failed"
  }.freeze

  def initialize(item:)
    @item = item
    @errors = []
  end

  def call
    start_time = Time.current
    Rails.logger.info("🤖 [ItemAIEnrichmentService] ========== ENRICHISSEMENT AI PRODUIT ==========")
    Rails.logger.info("📋 [ItemAI EnrichmentService] Item ID: #{@item.id} | Shop: #{@item.shop.name} | Name: #{@item.name.presence || 'Vide'}")

    unless ai_enabled?
      duration = (Time.current - start_time).round(3)
      Rails.logger.warn("⚠️ [ItemAIEnrichmentService] AI désactivé pour ce shop après #{duration}s - Shop ID: #{@item.shop.id}")
      return Result.new(success?: false, item: @item, errors: [ "IA non activée pour cette boutique" ])
    end
    Rails.logger.info("✅ [ItemAIEnrichmentService] AI activé pour ce shop")

    Rails.logger.info("🤖 [ItemAIEnrichmentService] Démarrage enrichissement IA - item_id: #{@item.id}")

    @item.update(ai_enrichment_status: AI_ENRICHMENT_STATUSES[:processing])
    Rails.logger.info("⚡ [ItemAIEnrichmentService] Status: processing")

    begin
      enrichment_start = Time.current
      enriched_data = generate_enriched_content
      enrichment_duration = (Time.current - enrichment_start).round(3)

      if enriched_data.present?
        Rails.logger.info("✅ [ItemAIEnrichmentService] Contenu généré en #{enrichment_duration}s")

        update_start = Time.current
        update_item_with_enriched_data(enriched_data)
        update_duration = (Time.current - update_start).round(3)

        @item.update(ai_enrichment_status: AI_ENRICHMENT_STATUSES[:completed])

        total_duration = (Time.current - start_time).round(3)
        Rails.logger.info("✅ [ItemAIEnrichmentService] Enrichissement réussi en #{total_duration}s (AI: #{enrichment_duration}s | Update: #{update_duration}s) - item_id: #{@item.id}")
        Result.new(success?: true, item: @item, enriched_data: enriched_data, errors: [])
      else
        enrichment_duration = (Time.current - enrichment_start).round(3)
        Rails.logger.error("❌ [ItemAIEnrichmentService] Aucune donnée générée après #{enrichment_duration}s")
        raise StandardError, "Aucune donnée enrichie générée"
      end
    rescue => e
      duration = (Time.current - start_time).round(3)
      error_message = extract_error_message(e)
      Rails.logger.error("❌ [ItemAIEnrichmentService] Erreur enrichissement après #{duration}s - item_id: #{@item.id}")
      Rails.logger.error("❌ [ItemAIEnrichmentService] #{e.class}: #{error_message}")
      Rails.logger.error("❌ [ItemAIEnrichmentService] Backtrace: #{e.backtrace.first(3).join('\n')}")

      # Ne pas marquer comme failed si c'est un problème de quota (pour permettre de réessayer plus tard)
      if quota_error?(error_message)
        @item.update(ai_enrichment_status: AI_ENRICHMENT_STATUSES[:pending])
        Rails.logger.warn("⚠️ [ItemAIEnrichmentService] Quota OpenAI dépassé - item_id: #{@item.id}, statut remis à pending")
      else
        @item.update(ai_enrichment_status: AI_ENRICHMENT_STATUSES[:failed])
        Rails.logger.warn("⚠️ [ItemAIEnrichmentService] Statut: failed")
      end

      Result.new(success?: false, item: @item, errors: [ error_message ])
    end
  end

  private

  attr_reader :item

  def ai_enabled?
    @item.shop.capabilities.ai_background_generation_enabled?
  end

  def generate_enriched_content
    agent_start = Time.current
    Rails.logger.info("🚀 [ItemAIEnrichmentService] Appel agent AI...")
    Rails.logger.info("📋 [ItemAIEnrichmentService] Catégorie: #{@item.product_sub_category&.product_category&.name} | Sous-cat: #{@item.product_sub_category&.name}")

    agent = ItemEnrichmentAgent.with(
      item_name: @item.name,
      category: @item.product_sub_category&.product_category&.name,
      sub_category: @item.product_sub_category&.name,
      current_description: @item.description,
      price: @item.default_variant&.price,
      currency: @item.currency&.code
    )

    response = agent.enrich_product.generate_now
    agent_duration = (Time.current - agent_start).round(3)
    Rails.logger.info("⏱️ [ItemAIEnrichmentService] Agent AI terminé en #{agent_duration}s")

    # response.message est un objet Assistant, utiliser .text pour obtenir le texte
    response_text = response.message.text
    Rails.logger.info("📝 [ItemAIEnrichmentService] Réponse reçue - Length: #{response_text.length} chars")

    parse_start = Time.current
    enriched_data = parse_enriched_response(response_text)
    parse_duration = (Time.current - parse_start).round(3)
    Rails.logger.info("✅ [ItemAIEnrichmentService] Parsing réussi en #{parse_duration}s")

    enriched_data
  rescue => e
    agent_duration = (Time.current - agent_start).round(3)
    Rails.logger.error("❌ [ItemAIEnrichmentService] Erreur génération IA après #{agent_duration}s - #{e.class}: #{e.message}")
    Rails.logger.error("❌ [ItemAIEnrichmentService] Backtrace: #{e.backtrace.first(3).join('\n')}")
    raise
  end

  def parse_enriched_response(response_text)
    Rails.logger.info("🔍 [ItemAIEnrichmentService] Parsing réponse AI...")

    # Nettoyer la réponse (enlever markdown, code blocks, etc.)
    cleaned_text = response_text.strip
    cleaned_text = cleaned_text.gsub(/```json\s*/, "").gsub(/```\s*/, "")
    cleaned_text = cleaned_text.strip
    Rails.logger.info("🧹 [ItemAIEnrichmentService] Texte nettoyé - Length: #{cleaned_text.length} chars")

    # Parser le JSON
    parsed = JSON.parse(cleaned_text)
    Rails.logger.info("✅ [ItemAIEnrichmentService] JSON parsé - Keys: #{parsed.keys.join(', ')}")
    parsed
  rescue JSON::ParserError => e
    Rails.logger.warn("⚠️ [ItemAIEnrichmentService] Erreur parsing JSON: #{e.message}")
    Rails.logger.info("📝 [ItemAIEnrichmentService] Réponse: #{response_text[0..200]}")
    # Fallback: essayer d'extraire le JSON même s'il y a du texte autour
    json_match = cleaned_text.match(/\{.*\}/m)
    if json_match
      Rails.logger.info("🔍 [ItemAIEnrichmentService] JSON extrait par regex, nouvelle tentative...")
      parsed_fallback = JSON.parse(json_match[0])
      Rails.logger.info("✅ [ItemAIEnrichmentService] Parsing fallback réussi - Keys: #{parsed_fallback.keys.join(', ')}")
      parsed_fallback
    else
      Rails.logger.error("❌ [ItemAIEnrichmentService] Impossible d'extraire le JSON")
      raise StandardError, "Impossible de parser la réponse JSON de l'IA"
    end
  end

  def extract_error_message(error)
    # Handle different error formats from Active Agent / OpenAI
    if error.respond_to?(:message)
      msg = error.message
      # Check if it's a hash/JSON error response
      if msg.is_a?(Hash)
        if msg[:body] && msg[:body][:error]
          return msg[:body][:error][:message] || msg[:body][:error].to_s
        end
        return msg.to_s
      end
      return msg.to_s
    end
    error.to_s
  end

  def quota_error?(error_message)
    # Check if the error is related to quota/rate limiting
    error_str = error_message.to_s.downcase
    error_str.include?("quota") ||
    error_str.include?("rate limit") ||
    error_str.include?("429") ||
    error_str.include?("insufficient_quota")
  end

  def update_item_with_enriched_data(enriched_data)
    updates = {}
    ai_generated = {}

    Rails.logger.info("📝 [ItemAIEnrichmentService] Mise à jour item avec données AI...")

    # Mettre à jour uniquement les champs vides
    if @item.name.blank? && enriched_data["name"].present?
      updates[:name] = enriched_data["name"]
      ai_generated[:name] = true
      Rails.logger.info("✏️ [ItemAIEnrichmentService] Nom généré: #{enriched_data['name'].truncate(50)}")
    end

    if @item.description.blank? && enriched_data["description"].present?
      updates[:description] = enriched_data["description"]
      ai_generated[:description] = true
      Rails.logger.info("✏️ [ItemAIEnrichmentService] Description générée - Length: #{enriched_data['description'].length} chars")
    end

    if enriched_data["meta_title"].present?
      updates[:meta_title] = enriched_data["meta_title"]
      ai_generated[:meta_title] = true
      Rails.logger.info("🏷️ [ItemAIEnrichmentService] Meta title généré: #{enriched_data['meta_title'].truncate(50)}")
    end

    if enriched_data["meta_description"].present?
      updates[:meta_description] = enriched_data["meta_description"]
      ai_generated[:meta_description] = true
      Rails.logger.info("🏷️ [ItemAIEnrichmentService] Meta description générée - Length: #{enriched_data['meta_description'].length} chars")
    end

    if @item.keywords.blank? && enriched_data["keywords"].present?
      kw = enriched_data["keywords"]
      updates[:keywords] = kw.is_a?(Array) ? kw.join(", ") : kw.to_s
      ai_generated[:keywords] = true
      Rails.logger.info("🏷️ [ItemAIEnrichmentService] Mots-clés générés pour le produit")
    end

    # Ne PAS mettre à jour le slug automatiquement pour éviter de casser les liens existants
    # Le slug est généré par FriendlyId basé sur le nom, et ne devrait être changé que manuellement
    # Si un slug_suggestion est fourni, on le stocke dans ai_generated_fields pour référence future
    if enriched_data["slug_suggestion"].present?
      ai_generated[:slug_suggestion] = enriched_data["slug_suggestion"]
      # Ne mettre à jour le slug QUE si le slug actuel est vraiment vide ou très basique
      # et seulement si le nom a été généré par l'IA (pour éviter de casser les slugs existants)
      if @item.slug.blank? && ai_generated[:name]
        # Si le nom vient de l'IA, on peut utiliser le slug suggéré
        updates[:slug] = enriched_data["slug_suggestion"]
        Rails.logger.info("🔗 [ItemAIEnrichmentService] Slug généré: #{enriched_data['slug_suggestion']}")
      end
    end

    # Sauvegarder les champs générés par IA
    current_ai_fields = @item.ai_generated_fields || {}
    updates[:ai_generated_fields] = current_ai_fields.merge(ai_generated)

    if updates.any?
      @item.update!(updates)
      Rails.logger.info("✅ [ItemAIEnrichmentService] Item mis à jour - #{updates.keys.count} champs modifiés")
    else
      Rails.logger.info("ℹ️ [ItemAIEnrichmentService] Aucun champ à mettre à jour (tous non-vides)")
    end
  end
end
