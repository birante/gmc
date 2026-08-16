# frozen_string_literal: true

class ItemAIPreviewService
  Result = Struct.new(:success?, :preview_data, :errors, keyword_init: true)

  def initialize(item_params:)
    @item_params = item_params
    @errors = []
  end

  def call
    start_time = Time.current
    Rails.logger.info("👁️ [ItemAIPreviewService] ========== PRÉVISUALISATION AI PRODUIT ==========")
    Rails.logger.info("📋 [ItemAIPreviewService] Nom: #{@item_params[:name].presence || 'Vide'} | Catégorie: #{@item_params[:category_name].presence || 'N/A'}")
    Rails.logger.info("💰 [ItemAIPreviewService] Prix: #{@item_params[:price]} #{@item_params[:currency_code]}")

    begin
      preview_start = Time.current
      preview_data = generate_preview_content
      preview_duration = (Time.current - preview_start).round(3)

      if preview_data.present?
        total_duration = (Time.current - start_time).round(3)
        fields_count = preview_data.keys.count
        Rails.logger.info("✅ [ItemAIPreviewService] Preview générée avec succès en #{total_duration}s (AI: #{preview_duration}s)")
        Rails.logger.info("📊 [ItemAIPreviewService] Champs générés: #{fields_count} (#{preview_data.keys.join(', ')})")
        Result.new(success?: true, preview_data: preview_data, errors: [])
      else
        total_duration = (Time.current - start_time).round(3)
        Rails.logger.error("❌ [ItemAIPreviewService] Aucune donnée générée après #{total_duration}s")
        raise StandardError, "Aucune donnée de preview générée"
      end
    rescue => e
      duration = (Time.current - start_time).round(3)
      Rails.logger.error("❌ [ItemAIPreviewService] EXCEPTION après #{duration}s - #{e.class}: #{e.message}")
      Rails.logger.error("❌ [ItemAIPreviewService] Backtrace: #{e.backtrace.first(5).join('\n')}")
      Result.new(success?: false, preview_data: nil, errors: [ e.message ])
    end
  end

  private

  def generate_preview_content
    agent_start = Time.current
    Rails.logger.info("🚀 [ItemAIPreviewService] Appel agent AI pour preview...")
    Rails.logger.info("📋 [ItemAIPreviewService] Params - Cat: #{@item_params[:category_name]} | Sous-cat: #{@item_params[:sub_category_name]}")

    agent = ItemEnrichmentAgent.with(
      item_name: @item_params[:name],
      category: @item_params[:category_name],
      sub_category: @item_params[:sub_category_name],
      current_description: @item_params[:description],
      price: @item_params[:price],
      currency: @item_params[:currency_code]
    )

    response = agent.generate_preview.generate_now
    agent_duration = (Time.current - agent_start).round(3)
    Rails.logger.info("⏱️ [ItemAIPreviewService] Agent AI terminé en #{agent_duration}s")

    # response.message est un objet Assistant, utiliser .text pour obtenir le texte
    response_text = response.message.text
    Rails.logger.info("📝 [ItemAIPreviewService] Réponse reçue - Length: #{response_text.length} chars")

    parse_start = Time.current
    preview_data = parse_enriched_response(response_text)
    parse_duration = (Time.current - parse_start).round(3)
    Rails.logger.info("✅ [ItemAIPreviewService] Parsing réussi en #{parse_duration}s")

    preview_data
  rescue => e
    agent_duration = (Time.current - agent_start).round(3)
    Rails.logger.error("❌ [ItemAIPreviewService] Erreur génération IA après #{agent_duration}s - #{e.class}: #{e.message}")
    Rails.logger.error("❌ [ItemAIPreviewService] Backtrace: #{e.backtrace.first(3).join('\n')}")
    raise
  end

  def parse_enriched_response(response_text)
    Rails.logger.info("🔍 [ItemAIPreviewService] Parsing réponse AI...")

    # Nettoyer la réponse (enlever markdown, code blocks, etc.)
    cleaned_text = response_text.strip
    cleaned_text = cleaned_text.gsub(/```json\s*/, "").gsub(/```\s*/, "")
    cleaned_text = cleaned_text.strip
    Rails.logger.info("🧹 [ItemAIPreviewService] Texte nettoyé - Length: #{cleaned_text.length} chars")

    parsed = try_parse_json(cleaned_text)
    if parsed
      Rails.logger.info("✅ [ItemAIPreviewService] JSON parsé - Keys: #{parsed.keys.join(', ')}")
      return parsed
    end

    # Fallback: extraire le JSON même s'il y a du texte autour
    json_match = cleaned_text.match(/\{.*\}/m)
    if json_match
      Rails.logger.info("🔍 [ItemAIPreviewService] JSON extrait par regex, nouvelle tentative...")
      parsed = try_parse_json(json_match[0])
      if parsed
        Rails.logger.info("✅ [ItemAIPreviewService] Parsing fallback réussi - Keys: #{parsed.keys.join(', ')}")
        return parsed
      end
    end

    Rails.logger.error("❌ [ItemAIPreviewService] Impossible d'extraire le JSON")
    Rails.logger.info("📝 [ItemAIPreviewService] Réponse: #{response_text[0..200]}")
    raise StandardError, "Impossible de parser la réponse JSON de l'IA"
  end

  # Parse le JSON en essayant plusieurs stratégies (réponse tronquée possible)
  def try_parse_json(text)
    JSON.parse(text)
  rescue JSON::ParserError => e
    Rails.logger.warn("⚠️ [ItemAIPreviewService] Erreur parsing JSON: #{e.message}")

    # Réparer une réponse tronquée : chaîne non fermée puis fin d'objet manquante
    repaired = text.rstrip
    return nil if repaired.empty?

    # Si le JSON ne se termine pas par }, la réponse a peut-être été tronquée
    return nil if repaired.end_with?("}")

    # Tenter de réparer : chaîne coupée → fermer avec " puis }
    to_append = repaired.end_with?('"') ? "}" : '"}'
    begin
      return JSON.parse(repaired + to_append)
    rescue JSON::ParserError
      nil
    end

    nil
  end
end
