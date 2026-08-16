module ApplicationHelper
  # 🚀 Charge les catégories actives avec eager-loading des sous-catégories pour la navbar
  # Cache pour éviter les requêtes répétées et les N+1 queries
  def active_categories_with_subcategories
    @active_categories ||= Rails.cache.fetch("navbar/categories/v2/#{I18n.locale}", expires_in: 2.hours) do
      ProductCategory
        .where(is_active: true)
        .includes(sub_categories: :icon_attachment)
        .where(sub_categories: { is_active: true })
        .order(:position, :name)
        .to_a
    end
  end

  # Helper pour formater le montant du panier
  def format_cart_amount(cart)
    return "0 FCFA" unless cart

    amount = cart.total_amount || 0
    "#{amount.to_i} FCFA"
  end

  # Helper pour obtenir le nombre d'items dans le panier (optimisé sans création)
  def cart_items_count(cart = nil)
    # Utiliser le panier passé en argument, sinon récupérer le panier readonly
    cart ||= controller.send(:current_cart_readonly) if controller.respond_to?(:current_cart_readonly, true)
    return 0 unless cart

    # Nombre de produits distincts (lignes du panier), pas la somme des quantités.
    # `size` réutilise l'association préchargée si disponible.
    cart.cart_items.size
  end

  # Helpers pour l'internationalisation
  def current_locale_name
    case I18n.locale
    when :fr then "Français"
    when :en then "English"
    else "Français"
    end
  end

  def locale_flag
    case I18n.locale
    when :fr then "🇫🇷"
    when :en then "🇬🇧"
    else "🇫🇷"
    end
  end

  def other_locale
    I18n.locale == :fr ? :en : :fr
  end

  # Helper pour obtenir la liste des pays avec leurs codes téléphoniques pour le composant phone field
  def countries_for_phone_field(priority_countries = [ "SN", "FR", "ML", "CI", "BF", "MR", "GN", "GM" ])
    countries = ISO3166::Country.all.map do |country|
      {
        code: country.alpha2,
        name: country.iso_short_name,
        phoneCode: country.country_code.present? ? "+#{country.country_code}" : ""
      }
    end.reject { |c| c[:phoneCode].blank? }.sort_by { |c| c[:name] }

    # Mettre les pays prioritaires en premier
    priority = countries.select { |c| priority_countries.include?(c[:code]) }
    others = countries.reject { |c| priority_countries.include?(c[:code]) }

    priority + others
  end

  # Helper pour obtenir l'emoji drapeau d'un pays à partir de son code ISO2
  def get_country_flag(country_code)
    return "🌍" if country_code.blank?

    # Convertir le code pays (ex: "SN") en emoji drapeau
    # Les emojis drapeaux utilisent les Regional Indicator Symbols
    # A = U+1F1E6, B = U+1F1E7, etc.
    code_points = country_code
      .to_s
      .upcase
      .split("")
      .map { |char| 0x1F1E6 + (char.ord - "A".ord) }

    code_points.pack("U*")
  rescue
    "🌍"
  end

  # Surcharge de image_tag pour gérer gracieusement les assets manquants en test
  def image_tag(source, **options)
    super
  rescue StandardError => e
    if Rails.env.test? && e.message.include?("asset") && e.message.include?("not found")
      # En test, retourner une image placeholder transparente si l'asset n'est pas trouvé
      tag.img(**options.merge(
        src: "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='1' height='1'/%3E",
        alt: options[:alt] || "",
        class: "#{options[:class]} test-placeholder".strip
      ))
    else
      raise e
    end
  end

  def format_delivery_zone_description(description)
    text = description.to_s.strip
    return "" if text.blank?

    segments = text.split(/\s*\|\s*/)

    safe_join(segments, tag.br)
  end

  # ==========================================
  # PRICE HELPERS WITH PROMO SUPPORT
  # ==========================================

  # Retourne le prix actuel d'une variante (avec promo si applicable)
  def current_price_for(variant)
    return 0 unless variant
    return variant.price unless variant.respond_to?(:current_price)
    variant.current_price
  end

  # Retourne le prix original d'une variante (avant promo)
  def original_price_for(variant)
    return 0 unless variant
    return variant.price unless variant.respond_to?(:original_price)
    variant.original_price
  end

  # Retourne le pourcentage de réduction pour une variante
  def discount_percentage_for(variant)
    return 0 unless variant
    return 0 unless variant.respond_to?(:discount_percentage)
    variant.discount_percentage
  end

  # Vérifie si une variante est en promo
  def on_sale?(variant)
    return false unless variant
    return false unless variant.respond_to?(:on_sale?)
    variant.on_sale?
  end

  # Formate le prix avec support promo
  def format_price_with_promo(variant, options = {})
    return "N/A" unless variant

    current_price = current_price_for(variant)
    original_price = original_price_for(variant)
    discount_percent = discount_percentage_for(variant)

    currency_symbol = options[:currency] || variant.item&.currency&.symbol || "FCFA"
    show_original = options.fetch(:show_original, true)

    html = content_tag(:span,
      number_to_currency(current_price, unit: "", precision: 0, delimiter: ".", separator: ",") + " " + currency_symbol,
      class: options[:current_price_class] || "text-[22px] font-bold text-[#dc2626]"
    )

    if show_original && discount_percent > 0 && original_price > current_price
      html += content_tag(:span,
        number_to_currency(original_price, unit: "", precision: 0, delimiter: ".", separator: ",") + " " + currency_symbol,
        class: options[:original_price_class] || "text-[16.1px] font-medium text-[#111827] line-through ml-2"
      )
    end

    html
  end
end
