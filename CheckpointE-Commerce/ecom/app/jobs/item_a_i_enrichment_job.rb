# frozen_string_literal: true

class ItemAIEnrichmentJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: ->(executions) { executions * 2 }, attempts: 3 do |job, error|
    Rails.logger.error("❌ [ItemAIEnrichmentJob] Retry #{job.executions} - item_id: #{job.arguments.first}, error: #{error.message}")
  end

  def perform(item_id)
    item = Item.find_by(id: item_id)
    return unless item

    Rails.logger.info("🤖 [ItemAIEnrichmentJob] Traitement enrichissement IA - item_id: #{item_id}")

        # Load the service - ensure it's available in background jobs
        # Rails autoloading may not work in background job context
        unless defined?(ItemAIEnrichmentService)
          load Rails.root.join("app", "services", "item_ai_enrichment_service.rb")
        end

        service = ItemAIEnrichmentService.new(item: item)
    result = service.call

    if result.success?
      Rails.logger.info("✅ [ItemAIEnrichmentJob] Enrichissement terminé - item_id: #{item_id}")
    else
      Rails.logger.error("❌ [ItemAIEnrichmentJob] Échec enrichissement - item_id: #{item_id}, erreurs: #{result.errors.join(', ')}")
      raise StandardError, "Échec enrichissement IA: #{result.errors.join(', ')}"
    end
  end
end
