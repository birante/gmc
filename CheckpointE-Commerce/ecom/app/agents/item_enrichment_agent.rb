# frozen_string_literal: true

class ItemEnrichmentAgent < ApplicationAgent
  generate_with :openai,
    # Remplacer "gpt-4o-mini" par "gpt-4.1-nano"
    model: "gpt-4.1-nano",
    instructions: <<~INSTRUCTIONS
      You are an expert e-commerce product description writer specializing in SEO optimization.
      Your task is to generate compelling, SEO-friendly product content in French.

      Guidelines:
      - Write in French (français)
      - Be concise but informative
      - Include relevant keywords naturally
      - Focus on benefits and features
      - Optimize for search engines
      - Keep descriptions engaging and professional
    INSTRUCTIONS

  # Action principale pour enrichir un produit
  def enrich_product
    @item_name = params[:item_name]
    @category = params[:category]
    @sub_category = params[:sub_category]
    @current_description = params[:current_description]
    @price = params[:price]
    @currency = params[:currency]

    # Active Agent will automatically use the template at app/views/agents/item_enrichment/enrich_product.text.erb
    # Explicitly render the prompt to ensure it's passed to the API
    rendered_prompt = prompt
    rendered_prompt.present? ? rendered_prompt : raise("Prompt template could not be rendered")
  end

  # Action pour générer une preview (même logique mais sans sauvegarde)
  def generate_preview
    @item_name = params[:item_name]
    @category = params[:category]
    @sub_category = params[:sub_category]
    @current_description = params[:current_description]
    @price = params[:price]
    @currency = params[:currency]

    # Active Agent will automatically use the template at app/views/agents/item_enrichment/generate_preview.text.erb
    prompt
  end
end
