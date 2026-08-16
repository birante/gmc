# frozen_string_literal: true

require "csv"

module Vendors
  # Importe en masse des produits + variantes depuis un CSV.
  #
  # Auto-détecte le séparateur (`,` ou `;`), normalise les en-têtes, regroupe
  # les lignes par `nom` (chaque ligne supplémentaire devient une variante du
  # même produit), et applique l'idempotence : un produit dont le nom existe
  # déjà dans la boutique est silencieusement ignoré (compté comme `skipped`).
  #
  # Usage :
  #   result = Vendors::ItemBulkUploadService.new(shop: @current_shop, file: params[:file]).call
  #   result.created_count   # => 4
  #   result.skipped_count   # => 1   (doublons ignorés)
  #   result.errors          # => ["Ligne 3 : prix invalide", ...]
  class ItemBulkUploadService
    Result = Struct.new(:success?, :created_count, :skipped_count, :errors, keyword_init: true)

    REQUIRED_HEADERS = %w[nom].freeze

    KNOWN_HEADERS = %w[
      nom description prix stock sous_categorie devise
      attribut_1 valeur_1 attribut_2 valeur_2
      prix_variante stock_variante
    ].freeze

    def initialize(shop:, file:)
      @shop = shop
      @file = file
      @errors = []
      @created_count = 0
      @skipped_count = 0
    end

    def call
      return failure("Aucun fichier fourni") unless @file
      return failure("La boutique est introuvable") unless @shop

      rows = parse_csv
      return failure(@errors.first) if rows.nil?

      missing = REQUIRED_HEADERS - rows.first.keys
      return failure("En-têtes manquants : #{missing.join(', ')}") if missing.any?

      group_by_product(rows).each do |product_name, product_rows|
        process_product(product_name, product_rows)
      end

      Result.new(
        success?: @errors.empty? || @created_count.positive?,
        created_count: @created_count,
        skipped_count: @skipped_count,
        errors: @errors
      )
    end

    private

    # ---------- Parsing ----------

    def parse_csv
      raw = read_file_content
      return nil if raw.nil?

      separator = detect_separator(raw)
      CSV.parse(raw, headers: true, col_sep: separator, skip_blanks: true).map do |row|
        normalize_keys(row.to_h)
      end.reject { |h| h.values.all?(&:blank?) }
    rescue CSV::MalformedCSVError => e
      @errors << "Fichier CSV invalide : #{e.message}"
      nil
    end

    def read_file_content
      content = if @file.respond_to?(:read)
        @file.read
      else
        File.read(@file)
      end
      # Force l'encodage UTF-8 puis retire le BOM éventuel laissé par Excel.
      # L'ordre est important : sub avec regex UTF-8 sur une chaîne ASCII-8BIT
      # (cas typique d'un upload Rack) lève "incompatible encoding regexp match".
      content.force_encoding("UTF-8").delete_prefix("\xEF\xBB\xBF")
    rescue StandardError => e
      @errors << "Lecture du fichier impossible : #{e.message}"
      nil
    end

    def detect_separator(raw)
      first_line = raw.lines.first.to_s
      first_line.count(";") > first_line.count(",") ? ";" : ","
    end

    def normalize_keys(hash)
      hash.transform_keys do |key|
        key.to_s.strip.downcase.gsub(/\s+/, "_").gsub(/[^\w]/, "")
      end
    end

    # ---------- Grouping ----------

    def group_by_product(rows)
      rows.group_by { |row| row["nom"].to_s.strip }
          .reject { |name, _| name.blank? }
    end

    # ---------- Per-product creation ----------

    def process_product(product_name, product_rows)
      if product_already_exists?(product_name)
        @skipped_count += 1
        return
      end

      base_row = product_rows.first
      ActiveRecord::Base.transaction do
        item = build_item(product_name, base_row)
        item.save!
        attach_variants(item, product_rows)
        @created_count += 1
      end
    rescue ActiveRecord::RecordInvalid => e
      @errors << "Ligne « #{product_name} » : #{e.record.errors.full_messages.join(', ')}"
    rescue StandardError => e
      Rails.logger.error("[ItemBulkUploadService] Erreur produit #{product_name}: #{e.class} #{e.message}")
      @errors << "Ligne « #{product_name} » : #{e.message}"
    end

    def product_already_exists?(name)
      @shop.items.where("LOWER(name) = ?", name.downcase).exists?
    end

    def build_item(product_name, row)
      item = @shop.items.build(
        name: product_name,
        description: row["description"].presence,
        product_sub_category: lookup_sub_category(row["sous_categorie"]),
        currency: lookup_currency(row["devise"]),
        validation_status: "pending"
      )

      base_price = parse_decimal(row["prix"])
      base_stock = parse_integer(row["stock"])
      item.default_price = base_price if base_price&.positive?
      item.default_stock_quantity = base_stock if base_stock

      item
    end

    def attach_variants(item, product_rows)
      variant_rows = product_rows.select { |r| r["valeur_1"].present? || r["valeur_2"].present? }
      return if variant_rows.empty? # le default_variant créé par le model suffit

      variant_payload = variant_rows.map { |row| build_variant_payload(item, row) }
      VariantCreationService.new(item).process_variants_with_attributes(variant_payload)
    end

    def build_variant_payload(item, row)
      base_price = parse_decimal(row["prix"]) || item.default_price
      base_stock = parse_integer(row["stock"]) || item.default_stock_quantity || 0

      {
        "price" => parse_decimal(row["prix_variante"]) || base_price,
        "stock_quantity" => parse_integer(row["stock_variante"]) || base_stock,
        "combination_data" => combination_data_from_row(row)
      }
    end

    def combination_data_from_row(row)
      pairs = []
      pairs << { "name" => row["attribut_1"].to_s.strip, "value" => row["valeur_1"].to_s.strip } if row["valeur_1"].present?
      pairs << { "name" => row["attribut_2"].to_s.strip, "value" => row["valeur_2"].to_s.strip } if row["valeur_2"].present?
      pairs.map(&:to_json)
    end

    # ---------- Lookups ----------

    def lookup_sub_category(name)
      return nil if name.blank?
      ProductSubCategory.where(is_active: true).where("LOWER(TRIM(name)) = ?", name.to_s.strip.downcase).first
    end

    def lookup_currency(code)
      cleaned = code.to_s.strip.upcase
      currency = Currency.find_by(code: cleaned) if cleaned.present?
      currency || Currency.find_by(code: "XOF") || Currency.first
    end

    def parse_decimal(value)
      return nil if value.blank?
      BigDecimal(value.to_s.gsub(",", "."))
    rescue ArgumentError
      nil
    end

    def parse_integer(value)
      return nil if value.blank?
      Integer(value.to_s.tr(" ", ""))
    rescue ArgumentError
      nil
    end

    # ---------- Result helpers ----------

    def failure(message)
      Result.new(success?: false, created_count: 0, skipped_count: 0, errors: [ message ])
    end
  end
end
