# frozen_string_literal: true

module PlansHelper
  # Retourne les caractéristiques d'un plan pour l'affichage
  def plan_features(plan)
    plan_rules = plan.plan_rules.active.includes(:rule).index_by { |pr| pr.rule.code }

    ai_title = plan_rules["ai_title_description_enabled"]&.value || false
    ai_background = plan_rules["ai_background_generation_enabled"]&.value || false
    ai_photo = plan_rules["ai_photo_generation_enabled"]&.value || false
    max_employees = plan_rules["max_employees"]&.value || 1
    access_plan = plan.code == "ACCESS"

    {
      max_products: plan_rules["max_products"]&.value,
      max_employees: max_employees,
      multi_users: max_employees.nil? || max_employees.to_i > 1,
      analytics_enabled: plan_rules["analytics_enabled"]&.value || false,
      analytics_level: (plan_rules["analytics_enabled"]&.value || false) ? "standard" : "none",
      order_management: !access_plan,
      aa_delivery: !access_plan,
      delivery_priority: !access_plan,
      support_level: access_plan ? "standard" : "premium",
      meta_campaign_enabled: !access_plan,
      meta_campaign_days: nil,
      ai_title_description_enabled: ai_title,
      ai_background_generation_enabled: ai_background,
      ai_photo_generation_enabled: ai_photo,
      ai_level: if ai_photo
                  "premium"
                elsif ai_background || ai_title
                  "full"
                else
                  "basic"
                end
    }
  end

  # Retourne la couleur du gradient pour un plan
  def plan_gradient_color(plan_code)
    case plan_code
    when "ACCESS"
      "from-blue-500 to-blue-600"
    when "STARTER"
      "from-[#551694] to-[#7c1fc4]"
    when "BUSINESS"
      "from-purple-600 to-purple-700"
    when "PARTNER"
      "from-gray-700 to-gray-800"
    else
      "from-gray-500 to-gray-600"
    end
  end

  # Formate la limite de produits
  def format_product_limit(max)
    max ? "#{max} produits" : t("vendors.plans.unlimited_products")
  end

  # Formate la limite de collaborateurs
  def format_employee_limit(max)
    max ? "#{max} collaborateurs" : t("vendors.plans.unlimited_employees")
  end

  # Retourne un tableau des fonctionnalités IA activées
  def ai_features_list(features)
    list = []
    list << "Preview titre/description" if features[:ai_title_description_enabled]
    list << "Génération en arrière-plan" if features[:ai_background_generation_enabled]
    list << "Génération depuis photo" if features[:ai_photo_generation_enabled]
    list.empty? ? [ "Aucune" ] : list
  end

  # Retourne le texte résumé des fonctionnalités IA
  def ai_features_text(features)
    ai_list = ai_features_list(features)
    return "Aucune fonctionnalité IA" if ai_list == [ "Aucune" ]

    "IA : #{ai_list.join(' + ')}"
  end

  # Texte du niveau d'analytics pour la page plans vendeur
  def analytics_level_text(level)
    case level.to_s
    when "advanced", "premium"
      "Analytics avancés"
    when "basic", "standard"
      "Analytics standard"
    else
      "Analytics standard"
    end
  end

  # Texte du niveau de support pour la page plans vendeur
  def support_level_text(level)
    case level.to_s
    when "premium"
      "Support prioritaire"
    when "dedicated"
      "Support dédié"
    when "standard", "basic"
      "Support standard"
    else
      "Support standard"
    end
  end

  # Texte du niveau IA pour la page plans vendeur
  def ai_level_text(level)
    key = level.to_s.presence || "basic"
    I18n.t("vendors.plans.ai_level.#{key}", default: "IA basique")
  end

  # Texte des campagnes Meta (retourne nil si non activé)
  def meta_campaign_text(enabled, days)
    return nil unless enabled

    campaign_days = days.to_i
    return "Campagnes Meta incluses" if campaign_days <= 0

    "Campagnes Meta (#{campaign_days} jours/mois)"
  end

  # Sections de fonctionnalités affichées sur la carte plan (data-driven)
  def plan_feature_sections(plan:, features:, is_upgrade:, active_tab:)
    case plan.code.to_s
    when "STARTER"
      starter_plan_sections
    when "BUSINESS"
      business_plan_sections
    when "PARTNER"
      partner_plan_sections
    else
      [
        {
          title: "Fonctionnalités",
          compact: false,
          items: plan_primary_feature_items(code: plan.code.to_s, features: features, active_tab: active_tab)
        }
      ]
    end
  end

  private

  def starter_plan_sections
    [
      {
        title: "Fonctionnalités",
        compact: false,
        items: [
          { text: "Jusqu'à 15 produits listés", available: true },
          { text: "Boutique personnalisée", available: true },
          { text: "Gestion commandes & livraison intégrée", available: true },
          { text: "Analytics + IA SEO avancée", available: true },
          { text: "Support prioritaire", available: true },
          { text: "1 campagne Meta/mois", available: true }
        ]
      },
      {
        title: "Fonctionnalités supplémentaires à la charge du vendeur :",
        compact: true,
        items: [
          { text: "Campagnes Meta supplémentaires", available: true },
          { text: "Analytics avancé", available: true },
          { text: "Design boutique avancé", available: true },
          { text: "Livraison express", available: true },
          { text: "Mise en avant interne", available: true }
        ]
      }
    ]
  end

  def business_plan_sections
    [
      {
        title: "Fonctionnalités",
        compact: false,
        items: [
          { text: "Toutes les fonctionnalités de aa Starter plus :", available: true },
          { text: "Jusqu'à 30 produits listés", available: true },
          { text: "Boutique avancée & analytics complet", available: true },
          { text: "Livraison aa prioritaire", available: true },
          { text: "Accès multi-utilisateurs (3 max)", available: true },
          { text: "Rapport mensuel automatique", available: true },
          { text: "2 campagnes Meta/ mois", available: true }
        ]
      },
      {
        title: "Fonctionnalités supplémentaires à la charge du vendeur :",
        compact: true,
        items: [
          { text: "Campagnes Meta supplémentaires", available: true },
          { text: "Analytics Pro", available: true },
          { text: "Storefront premium", available: true },
          { text: "Livraison express", available: true },
          { text: "Mise en avant interne", available: true }
        ]
      }
    ]
  end

  def partner_plan_sections
    [
      {
        title: "Principe",
        compact: false,
        items: [
          { text: "Offre sans prix public", available: true },
          { text: "Conditions définies sur devis", available: true },
          { text: "Contrat personnalisé (6 à 12 mois)", available: true }
        ]
      },
      {
        title: "Services activables selon le contrat",
        compact: true,
        items: [
          { text: "Mini-site dédié & produits illimités", available: true },
          { text: "Livraison express", available: true },
          { text: "Reporting multi-canal avancé", available: true },
          { text: "Analytics multi-canal avancé", available: true },
          { text: "Campagnes Meta dédiées et mise en avant", available: true },
          { text: "Account Manager & support 24/7", available: true }
        ]
      }
    ]
  end

  def plan_primary_feature_items(code:, features:, active_tab:)
    case code
    when "ACCESS"
      [
        { text: "Jusqu'à #{format_product_limit(features[:max_products])}", available: true },
        { text: "Fiches produits complètes", available: true },
        { text: "Contact direct avec les acheteurs", available: true },
        { text: ai_level_text(features[:ai_level]), available: true },
        { text: "Pas de gestion de commandes", available: !features[:order_management] ? false : nil },
        { text: "Pas de livraison aa", available: !features[:aa_delivery] ? false : nil },
        { text: "Pas de campagnes Meta", available: !features[:meta_campaign_enabled] ? false : nil }
      ].compact.reject { |item| item[:available].nil? }
    else
      []
    end
  end

  # Options de paiement d'abonnement (source principale: base de données)
  def subscription_payment_options
    PaymentMethod.active
      .where(code: payment_method_visual_map.keys)
      .order(:name)
      .filter_map do |payment_method|
        map = payment_method_visual_map[payment_method.code]
        next unless map

        {
          withdraw_mode: map[:withdraw_mode],
          label: map[:label],
          icon: map[:icon]
        }
      end
  end

  def payment_method_visual_map
    {
      "wave_sn" => { withdraw_mode: "wave-senegal", label: "Wave", icon: "payments/wave.png" },
      "orange_money_sn" => { withdraw_mode: "orange-money-senegal", label: "Orange Money", icon: "payments/om.png" },
      "free_money_sn" => { withdraw_mode: "free-money-senegal", label: "Free Money", icon: "payments/yas.png" },
      "expresso_sn" => { withdraw_mode: "expresso-senegal", label: "Expresso", icon: "payments/expresso.png" }
    }
  end
end
