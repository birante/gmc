# frozen_string_literal: true

module Vendors
  class ItemUpdateService
    Result = Struct.new(:success?, :item, :errors, :status_changed, keyword_init: true)

    def initialize(item:, params:)
      @item = item
      @params = params
      @errors = []
    end

    def call
      start_time = Time.current
      Rails.logger.info("✏️ [Vendors::ItemUpdateService] ========== MISE À JOUR PRODUIT ==========")
      Rails.logger.info("📋 [Vendors::ItemUpdateService] Item ID: #{@item.id} | Shop: #{@item.shop.name}")
      Rails.logger.info("📝 [Vendors::ItemUpdateService] Nom: #{@item.name}")
      Rails.logger.debug("🔍 [Vendors::ItemUpdateService] Params reçus: #{@params.inspect}")

      # Sauvegarder l'ancien statut
      was_approved = @item.approved?
      Rails.logger.info("📊 [Vendors::ItemUpdateService] Statut actuel: #{@item.validation_status} | Approuvé: #{was_approved}")

      # Si le produit était approuvé, le repasser en pending AVANT la mise à jour
      # pour éviter que la validation exige delivery_category
      if was_approved
        @item.update_column(:validation_status, "pending")
        Rails.logger.info("🔄 [Vendors::ItemUpdateService] Produit repassé en pending - Item ID: #{@item.id}")
      end

      # Mettre à jour sans changer le statut de validation ni la devise
      update_params = @params.except(:validation_status, :currency_id)
      new_images = extract_new_images!(update_params)

      # Logger les attributs imbriqués pour debug
      if update_params[:item_attributes_attributes].present?
        attrs_count = update_params[:item_attributes_attributes].keys.count
        Rails.logger.debug("🏷️ [Vendors::ItemUpdateService] Mise à jour attributs - Count: #{attrs_count}")
      end

      update_start = Time.current
      if @item.update(update_params)
        attach_new_images(new_images)
        update_duration = (Time.current - update_start).round(3)
        total_duration = (Time.current - start_time).round(3)
        Rails.logger.info("✅ [Vendors::ItemUpdateService] Mise à jour réussie en #{total_duration}s (Update: #{update_duration}s) - Item ID: #{@item.id}")
        Result.new(success?: true, item: @item, errors: [], status_changed: was_approved)
      else
        update_duration = (Time.current - update_start).round(3)
        total_duration = (Time.current - start_time).round(3)
        Rails.logger.error("❌ [Vendors::ItemUpdateService] Échec mise à jour après #{total_duration}s - #{@item.errors.full_messages.join(', ')}")
        Result.new(success?: false, item: @item, errors: @item.errors.full_messages, status_changed: false)
      end
    rescue ActiveRecord::RecordInvalid => e
      duration = (Time.current - start_time).round(3)
      Rails.logger.error("❌ [Vendors::ItemUpdateService] Erreur validation après #{duration}s - #{e.class}: #{e.message}")
      Rails.logger.error("❌ [Vendors::ItemUpdateService] Backtrace: #{e.backtrace.first(3).join('\n')}")
      Result.new(success?: false, item: @item, errors: [ e.message ], status_changed: false)
    rescue => e
      duration = (Time.current - start_time).round(3)
      Rails.logger.error("❌ [Vendors::ItemUpdateService] EXCEPTION après #{duration}s - #{e.class}: #{e.message}")
      Rails.logger.error("❌ [Vendors::ItemUpdateService] Backtrace: #{e.backtrace.first(5).join('\n')}")
      Result.new(success?: false, item: @item, errors: [ e.message ], status_changed: false)
    end

    private

    # On extrait les images du hash de mise à jour pour éviter le comportement
    # de remplacement de ActiveStorage lors d'un update direct.
    def extract_new_images!(update_params)
      images = Array(update_params.delete(:images) || update_params.delete("images"))
      images.reject { |img| img.blank? }
    end

    def attach_new_images(images)
      return if images.blank?

      @item.images.attach(images)
    end
  end
end
