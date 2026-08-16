# db/seeds/shared.rb
# Seeds partagées entre développement et production
# Contient toutes les données essentielles communes
#
# NOTE: Les données de référence sont regroupées dans la constante SEED_REFERENCES
# (exportée à la fin du fichier) pour être utilisées dans development.rb et shared.rb.
# Les déclarations locales inutiles de variables ont été supprimées pour éviter la duplication.

# =========================================================================
# --- 1. DEVISES (ESSENTIEL) ---
# =========================================================================

_xof_currency = Currency.find_or_create_by!(code: 'XOF') do |c|
  c.name = 'Franc CFA (UEMOA)'
  c.symbol = 'F CFA'
  c.thousands_separator = ' '
  c.decimal_separator = '.'
  c.symbol_precedes_amount = false
  c.is_active = true
end
puts "✅ Devise XOF créée/mise à jour"

# =========================================================================
# --- 2. LOGISTIQUE COMPLÈTE ---
# =========================================================================

puts "Création des zones de livraison..."
zones_data = [
  {
    name: "Lot 1 - Plateau / Fann / Sacré-Cœur",
    description: "Lot 1 - Plateau / Fann / Sacré-Cœur: Plateau · Médina · Derklé · Castor · Point E · Fann Hock · Fann Résidence · Sacré-Cœur (1-3) · Liberté (1-3) · Amitié (1-3) · Ouagou Niayes · Gueule Tapée",
    base_fee: 1500.00,
    min_delivery_time: 1,
    max_delivery_time: 3,
    is_active: true
  },
  {
    name: "Lot 2 - Sicap / HLM / Foire / Liberté (4-6)",
    description: "Lot 2 - Sicap / HLM / Foire / Liberté (4-6): Sicap (Baobab — Karak — Foire) · Keur Gorgui · Grand Dakar · HLM (1-6) · Bene Tally · Khar Yalla · Colobane · Nord Foire · Sud Foire · Niary Tally · Bourguiba · Mamelle · Liberté (4-6) · Sipress (1-2) · Scat Urbam",
    base_fee: 1500.00,
    min_delivery_time: 1,
    max_delivery_time: 3,
    is_active: true
  },
  {
    name: "Lot 3 - Yoff / Ouakam / Grand Yoff / Hann",
    description: "Lot 3 - Yoff / Ouakam / Grand Yoff / Hann: Ouakam · Yoff · Zone A · Zone B · Mermoz · Jet d'eau · Gibraltar · Grand Yoff · HLM Grand Yoff · Dieuppeul · Ker Yoff · Ouest Foire · Sicap Foire · Fass · Zone de Captage · Hann Maristes · Hann Marinas · Hann Bel Air · Yarakh",
    base_fee: 1500.00,
    min_delivery_time: 1,
    max_delivery_time: 3,
    is_active: true
  },
  {
    name: "Lot 4 - Almadies / Parcelles / Nord",
    description: "Lot 4 - Almadies / Parcelles / Nord: Almadies · Ngor · Golf · Fadia · Parcelles · Patte d'oie · Cité Dame · Cité Attaya · Cambérène · Diamalaye (1-2) · Grand Médine · Soprime",
    base_fee: 2000.00,
    min_delivery_time: 2,
    max_delivery_time: 4,
    is_active: true
  },
  {
    name: "Lot 5 - Pikine / Dalifort",
    description: "Lot 5 - Pikine / Dalifort: Pikine · Dalifort · Mixta · Grand Médine",
    base_fee: 2000.00,
    min_delivery_time: 2,
    max_delivery_time: 4,
    is_active: true
  },
  {
    name: "Lot 6 - Guediawaye / Yeumbeul / Keur Massar",
    description: "Lot 6 - Guediawaye / Yeumbeul / Keur Massar: Guediawaye · Tivaouane Peulh · Keur Mbaye Fall · Diamagueune · Yeumbeul · Keur Massar · Malika",
    base_fee: 3000.00,
    min_delivery_time: 3,
    max_delivery_time: 6,
    is_active: true
  },
  {
    name: "Lot 7 - Mbao / Thiaroye / Rufisque / Kounoune",
    description: "Lot 7 - Mbao / Thiaroye / Rufisque / Kounoune: Grand Mbao · Petit Mbao · Mbao · Boune · Sicap Mbao · Fass Mbao · Zac Mbao · APIX · Thiaroye · Rufisque · Gadaye · Djaxaay · Kounoune · Diacksao · Mbatal",
    base_fee: 3000.00,
    min_delivery_time: 3,
    max_delivery_time: 6,
    is_active: true
  },
  {
    name: "Lot 8 - Régions",
    description: "Lot 8 - Axe Ouest: Thiès · Mbour · Diourbel · Touba · Kaolack · Fatick · Kaffrine | Lot 9 - Axe Nord: Saint-Louis · Louga · Matam · Kébémer | Lot 10 - Axe Sud & Est: Ziguinchor · Kolda · Sédhiou · Bignona · Tambacounda · Kédougou · Bakel",
    base_fee: 4000.00,
    min_delivery_time: 24,
    max_delivery_time: 72,
    is_active: true
  }
]

zones = {}
zones_data.each do |data|
  zone = DeliveryZone.find_or_create_by!(name: data[:name]) do |dz|
    dz.assign_attributes(data)
  end
  zones[data[:name]] = zone
end
puts "✅ #{zones_data.count} zones de livraison créées"

puts "Création des catégories de livraison..."
categories_delivery_data = [
  {
    code: 'standard',
    name: 'Standard',
    description: 'Colis courants (articles légers et moyens)',
    display_order: 1
  },
  {
    code: 'cargo',
    name: 'Cargo',
    description: 'Articles encombrants ou lourds (plus de 5 kg)',
    display_order: 2
  }
]

categories_delivery_data.each do |data|
  category = DeliveryCategory.find_or_create_by!(code: data[:code]) do |dc|
    dc.name = data[:name]
    dc.description = data[:description]
    dc.display_order = data[:display_order]
  end

  # Mettre à jour si la catégorie existait déjà
  if category.persisted? && (category.name != data[:name] || category.description != data[:description] || category.display_order != data[:display_order])
    category.update!(
      name: data[:name],
      description: data[:description],
      display_order: data[:display_order]
    )
  end
end
puts "✅ #{categories_delivery_data.count} catégories de livraison créées/mises à jour"

category_standard = DeliveryCategory.find_by!(code: 'standard')
category_cargo = DeliveryCategory.find_by!(code: 'cargo')
categories = { 'standard' => category_standard, 'cargo' => category_cargo }

puts "Création des prix de livraison..."
# Prix par zone selon politique de livraison
cargo_price_by_standard = {
  1500.0 => 5000.0,
  2000.0 => 5500.0,
  3000.0 => 6500.0,
  4000.0 => 7500.0
}

zones.each_value do |zone|
  standard_price = zone.base_fee.to_f
  cargo_price = cargo_price_by_standard.fetch(standard_price, 7500.0)

  DeliveryPrice.find_or_create_by!(delivery_zone: zone, delivery_category: categories['standard']) do |dp|
    dp.price = standard_price
  end

  DeliveryPrice.find_or_create_by!(delivery_zone: zone, delivery_category: categories['cargo']) do |dp|
    dp.price = cargo_price
  end
end
puts "✅ Prix de livraison créés"

puts "Création des créneaux horaires..."
slots_data = [
  { start_time: '9:00', end_time: '12:00', is_active: true },
  { start_time: '14:00', end_time: '18:00', is_active: true }
]

slots = {}
slots_data.each do |data|
  slot = DeliverySlot.find_or_create_by!(start_time: data[:start_time], end_time: data[:end_time]) do |ds|
    ds.assign_attributes(data)
  end
  slots[data[:start_time]] = slot
end
puts "✅ #{slots_data.count} créneaux horaires créés"

puts "Création des associations Zone-Slot..."
# Toutes les zones ont les deux créneaux par défaut
zones.each_value do |zone|
  ZoneSlot.find_or_create_by!(delivery_zone: zone, delivery_slot: slots['9:00'])
  ZoneSlot.find_or_create_by!(delivery_zone: zone, delivery_slot: slots['14:00'])
end
puts "✅ Associations Zone-Slot créées"

# =========================================================================
# --- 3. MOYENS DE PAIEMENT (ESSENTIEL) ---
# =========================================================================

puts "Création des moyens de paiement..."
payment_methods_data = [
  { code: 'paydunya', name: 'PayDunya (Mobile Money & Carte)', provider: 'paydunya', method_type: 0, is_active: false },
  { code: 'wave_sn', name: 'Wave Mobile Money', provider: 'Wave', method_type: 0, is_active: true },
  { code: 'orange_money_sn', name: 'Orange Money Sénégal', provider: 'Orange', method_type: 0, is_active: true },
  { code: 'free_money_sn', name: 'Free Money Sénégal', provider: 'Free', method_type: 0, is_active: false },
  { code: 'cb_visa', name: 'Carte Bancaire (VISA/Mastercard)', provider: 'CinetPay/PayGate', method_type: 1, is_active: false },
  { code: 'cash_on_delivery', name: 'Paiement à la livraison', provider: 'Internal', method_type: 2, is_active: true }
]

payment_methods_data.each do |data|
  PaymentMethod.find_or_create_by!(code: data[:code]) do |pm|
    pm.assign_attributes(data)
  end
end
puts "✅ #{payment_methods_data.count} moyens de paiement créés"

# NOTE: paydunya_pm a été supprimée ici (ligne 182 anciennement).
# La vraie référence utilisée se trouve dans SEED_REFERENCES (ligne 675).
# Tous les seeds doivent utiliser seed_references[:paydunya_pm] pour éviter la redondance.

# =========================================================================
# --- 4. CATÉGORIES DE PRODUITS COMPLÈTES ---
# =========================================================================
# Création des catégories et sous-catégories utilisées par les boutiques de test

puts "Création des catégories de produits..."

def create_main_category(name)
  ProductCategory.find_or_create_by!(name: name) do |c|
    c.is_active = true
  end
end

def create_subcategory(parent_category, name)
  ProductSubCategory.find_or_create_by!(name: name, product_category: parent_category) do |sc|
    sc.is_active = true
  end
end

# 1. MODE
mode = create_main_category("Mode")
create_subcategory(mode, "Femme - Accessoires")
create_subcategory(mode, "Femme - Vêtements")
create_subcategory(mode, "Homme - Vêtements")

# 2. BEAUTÉ & BIEN-ÊTRE
beaute = create_main_category("Beauté & Bien-être")
create_subcategory(beaute, "Femme - Soins visage & corps")
create_subcategory(beaute, "Homme - Parfums")

# 3. ÉLECTRONIQUE & HIGH-TECH
electronique = create_main_category("Électronique & High-Tech")
create_subcategory(electronique, "Téléphones & accessoires")
create_subcategory(electronique, "Moniteurs")

# 4. MAISON, CUISINE & DÉCORATION
maison = create_main_category("Maison, Cuisine & Décoration")
create_subcategory(maison, "Maison - Meubles & ameublement")

# 5. SUPERMARCHÉ & PRODUITS LOCAUX
supermarche = create_main_category("Supermarché & Produits Locaux")
create_subcategory(supermarche, "Alimentation & épicerie")

# 6. BÉBÉ & ENFANCE
enfance = create_main_category("Bébé & Enfance")
create_subcategory(enfance, "Jouets & jeux éducatifs")

# 7. SPORTS, LOISIRS & AUTO
sports = create_main_category("Sports, Loisirs & Auto")
create_subcategory(sports, "Équipements sportifs")

# 8. MADE IN SÉNÉGAL / MADE IN AFRICA
local = create_main_category("Made in Sénégal / Made in Africa")
create_subcategory(local, "Produits fabriqués localement")

puts "✅ Catégories de produits créées"

# =========================================================================
# --- 5. ATTRIBUTS DE PRODUITS ---
# =========================================================================

puts "Création des attributs de produits..."
# Couleur
couleur = ProductAttribute.find_or_create_by!(name: 'Couleur') do |attr|
  attr.description = 'Couleur du produit'
  attr.is_active = true
end

[ 'Rouge', 'Bleu', 'Vert', 'Jaune', 'Noir', 'Blanc', 'Rose', 'Orange', 'Violet', 'Gris' ].each do |value|
  ProductAttributeValue.find_or_create_by!(product_attribute: couleur, value: value)
end

# Taille
taille = ProductAttribute.find_or_create_by!(name: 'Taille') do |attr|
  attr.description = 'Taille du produit'
  attr.is_active = true
end

[ 'XS', 'S', 'M', 'L', 'XL', 'XXL', '3XL' ].each do |value|
  ProductAttributeValue.find_or_create_by!(product_attribute: taille, value: value)
end

# Matière
matiere = ProductAttribute.find_or_create_by!(name: 'Matière') do |attr|
  attr.description = 'Matière du produit'
  attr.is_active = true
end

[ 'Coton', 'Polyester', 'Cuir', 'Laine', 'Soie', 'Lin', 'Synthétique' ].each do |value|
  ProductAttributeValue.find_or_create_by!(product_attribute: matiere, value: value)
end

# Pointure (pour chaussures)
pointure = ProductAttribute.find_or_create_by!(name: 'Pointure') do |attr|
  attr.description = 'Pointure pour chaussures'
  attr.is_active = true
end

(35..46).each do |size|
  ProductAttributeValue.find_or_create_by!(product_attribute: pointure, value: size.to_s)
end

puts "✅ Attributs de produits créés avec succès!"
puts "   - Couleur: #{couleur.product_attribute_values.count} valeurs"
puts "   - Taille: #{taille.product_attribute_values.count} valeurs"
puts "   - Matière: #{matiere.product_attribute_values.count} valeurs"
puts "   - Pointure: #{pointure.product_attribute_values.count} valeurs"

# =========================================================================
# --- 6. SECTEURS D'ACTIVITÉ COMPLETS ---
# =========================================================================

puts "Création des secteurs d'activité..."
sectors_data = [
  { position: 1, name: 'Mode & Créateurs' },
  { position: 2, name: 'Beauté & Bien-être' },
  { position: 3, name: 'Électronique & High-Tech' },
  { position: 4, name: 'Maison, Cuisine & Décoration' },
  { position: 5, name: 'Supermarché & Produits Locaux' },
  { position: 6, name: 'Bébé & Enfance' },
  { position: 7, name: 'Sports, Loisirs & Auto' },
  { position: 8, name: 'Made in Sénégal / Made in Africa' }
]

sectors_data.each do |sector_data|
  Sector.find_or_create_by!(name: sector_data[:name]) do |sector|
    sector.position = sector_data[:position]
    sector.is_active = true
  end
end
puts "✅ #{sectors_data.count} secteurs d'activité créés"

# =========================================================================
# --- 7. PLATEFORMES SOCIALES ---
# =========================================================================

puts "Création des plateformes sociales..."
social_platforms = [
  { code: 'facebook', name: 'Facebook', icon_class: 'fab fa-facebook-f', position: 1 },
  { code: 'instagram', name: 'Instagram', icon_class: 'fab fa-instagram', position: 2 },
  { code: 'twitter', name: 'Twitter', icon_class: 'fab fa-twitter', position: 3 },
  { code: 'linkedin', name: 'LinkedIn', icon_class: 'fab fa-linkedin-in', position: 4 },
  { code: 'tiktok', name: 'TikTok', icon_class: 'fab fa-tiktok', position: 5 }
]

social_platforms.each do |platform_attrs|
  SocialPlatform.find_or_create_by!(code: platform_attrs[:code]) do |p|
    p.assign_attributes(platform_attrs)
    p.is_active = true
  end
end
puts "✅ Plateformes sociales créées"

# =========================================================================
# --- 8. OFFRES (RULES, PLANS, PLAN RULES) ---
# =========================================================================

# -------------------------------------------------------------------------
# RULES (DOIT ÊTRE CRÉÉ AVANT LES PLAN RULES)
# -------------------------------------------------------------------------

puts "Création des règles..."

# Pas de destroy_all : Rule est référencé par plan_rules (FK)
# Règles essentielles uniquement (simplifiées)
# NOTE: multi_users a été supprimé - utiliser max_employees > 1 à la place
rules_data = [
  { code: "max_products", description: "Nombre maximum de produits", rule_type: "integer", default_value: nil, is_active: true },
  { code: "analytics_enabled", description: "Analytics activé", rule_type: "boolean", default_value: false, is_active: true },
  { code: "max_employees", description: "Nombre maximum d'employés (1 = solo, >1 = multi-users)", rule_type: "integer", default_value: nil, is_active: true },
  { code: "ai_title_description_enabled", description: "IA - Génération titre/description en temps réel", rule_type: "boolean", default_value: false, is_active: true },
  { code: "ai_background_generation_enabled", description: "IA - Génération en arrière-plan", rule_type: "boolean", default_value: false, is_active: true },
  { code: "ai_photo_generation_enabled", description: "IA - Génération titre/description depuis photo", rule_type: "boolean", default_value: false, is_active: true }
]

rules_data.each do |rule_data|
  Rule.find_or_create_by!(code: rule_data[:code]) do |r|
    r.description = rule_data[:description]
    r.rule_type = rule_data[:rule_type]
    r.default_value = rule_data[:default_value]
    r.is_active = rule_data[:is_active]
  end
end

puts "✅ #{rules_data.count} règles créées/mises à jour"

# 🔒 Sécurité : helper strict pour récupérer les règles
# Disponible dans shared.rb et development.rb
def rule!(code)
  Rule.find_by!(code: code)
end

puts "✅ Règles créées avec succès"
puts ""

# -------------------------------------------------------------------------
# PLANS (partagés)
# -------------------------------------------------------------------------

puts "Création des plans..."

plans_data = {
  access: {
    code: "ACCESS",
    name: "aa Access",
    description: "Tester la vente en ligne sans abonnement",
    is_custom: false,
    is_active: true,
    price: 0.00,
    billing_period_months: 1
  },
  starter: {
    code: "STARTER",
    name: "aa Starter",
    description: "Commencer à vendre sérieusement",
    is_custom: false,
    is_active: true,
    price: 15000.00,
    billing_period_months: 3
  },
  business: {
    code: "BUSINESS",
    name: "aa Business",
    description: "Structurer et faire croître une marque",
    is_custom: false,
    is_active: true,
    price: 30000.00,
    billing_period_months: 3
  },
  partner: {
    code: "PARTNER",
    name: "aa Partner",
    description: "Partenariat grandes marques - sur mesure",
    is_custom: true,
    is_active: true,
    price: 0.00,
    billing_period_months: nil
  }
}

plans = {}
plans_data.each do |key, attrs|
  plans[key] = Plan.find_or_create_by!(code: attrs[:code]) do |p|
    p.assign_attributes(attrs)
  end
  plans[key].update!(attrs) if plans[key].persisted?
end
puts "✅ Plans créés/mis à jour"

# -------------------------------------------------------------------------
# PLAN RULES (partagées)
# -------------------------------------------------------------------------

puts "Création des règles pour chaque plan..."

plan_rules = {
  access: [
    [ "max_products", 10 ],
    [ "analytics_enabled", false ],
    [ "max_employees", 1 ],
    [ "ai_title_description_enabled", true ],
    [ "ai_background_generation_enabled", false ],
    [ "ai_photo_generation_enabled", false ]
  ],
  starter: [
    [ "max_products", nil ],
    [ "analytics_enabled", true ],
    [ "max_employees", 1 ],
    [ "ai_title_description_enabled", true ],
    [ "ai_background_generation_enabled", true ],
    [ "ai_photo_generation_enabled", false ]
  ],
  business: [
    [ "max_products", nil ],
    [ "analytics_enabled", true ],
    [ "max_employees", nil ],
    [ "ai_title_description_enabled", true ],
    [ "ai_background_generation_enabled", true ],
    [ "ai_photo_generation_enabled", true ]
  ],
  partner: [
    [ "max_products", nil ],
    [ "analytics_enabled", true ],
    [ "max_employees", nil ],
    [ "ai_title_description_enabled", true ],
    [ "ai_background_generation_enabled", true ],
    [ "ai_photo_generation_enabled", true ]
  ]
}

plan_rules.each do |plan_key, rules|
  rules.each do |code, value|
    rule = rule!(code)
    plan_rule = PlanRule.find_or_initialize_by(plan: plans[plan_key], rule: rule)
    plan_rule.assign_attributes(value: value, is_active: true)
    plan_rule.save!
  end
end
puts "✅ Plan rules créés/mis à jour"
puts ""

# =========================================================================
# --- 9. COMPTES ADMIN (ActiveAdmin) ---
# =========================================================================

if defined?(AdminUser)
  admin_emails = [
    "birantesy@gmail.com",
    "ousmane@aalogistics.com",
    "dieseck@aalogistics.com",
    "oumar@aalogistics.com"
  ]

  admin_emails.each do |email|
    manager = AdminUser.find_or_initialize_by(email: email)
    manager.role = "manager"
    # Toujours (re)définir le mot de passe pour que le seed donne un compte utilisable
    manager.password = "password@2026"
    manager.save!
    puts "✅ Compte manager admin (#{email}) — email: #{email}, mot de passe: password@2026"
  end
else
  puts "⚠️  AdminUser non chargé — exécutez les migrations puis relancez les seeds"
end

# =========================================================================
# --- 10. SECTIONS PAGE D'ACCUEIL (STRUCTURE) ---
# =========================================================================

puts "🏠 Création de la structure des sections de la page d'accueil..."

# 1. MARQUEE - Bandeau animé avec promos
HomePageSection.find_or_create_by!(section_type: "marquee") do |s|
  s.title = "Bandeau animé promotions"
  s.description = "Bandeau défilant avec les promotions en cours"
  s.is_active = true
  s.position = 1
end

# 2. HERO SLIDER - Carousel principal
HomePageSection.find_or_create_by!(section_type: "hero_slider") do |s|
  s.title = "Carousel principal"
  s.description = "Carousel hero avec les promotions principales"
  s.is_active = true
  s.position = 2
end

# 3. PROMO BANNERS - Bannières promotionnelles (4 bannières)
HomePageSection.find_or_create_by!(section_type: "promo_banners") do |s|
  s.title = "Bannières promotionnelles"
  s.description = "4 bannières promotionnelles principales"
  s.is_active = true
  s.position = 3
end

# 4. CATEGORIES - Catégories populaires
HomePageSection.find_or_create_by!(section_type: "categories") do |s|
  s.title = "Catégories populaires"
  s.description = "Grille scrollable des catégories les plus populaires"
  s.is_active = true
  s.position = 4
end

# 5. SECONDARY BANNERS - Bannières secondaires
HomePageSection.find_or_create_by!(section_type: "secondary_banners") do |s|
  s.title = "Bannières secondaires"
  s.description = "Bannières promotionnelles secondaires"
  s.is_active = true
  s.position = 5
end

# 6. TRENDING CATEGORIES - Tendances du moment
HomePageSection.find_or_create_by!(section_type: "trending_categories") do |s|
  s.title = "Tendances du moment"
  s.description = "Grid 4x4 de sous-catégories tendances"
  s.is_active = true
  s.position = 6
end

# 7. LOCAL SHOPS - Boutiques locales partenaires
HomePageSection.find_or_create_by!(section_type: "local_shops") do |s|
  s.title = "Boutiques locales"
  s.description = "Boutiques locales partenaires"
  s.is_active = true
  s.position = 7
end

# 8. OFFICIAL BRANDS - Boutiques officielles (logos marques)
HomePageSection.find_or_create_by!(section_type: "official_brands") do |s|
  s.title = "Marques officielles"
  s.description = "Logos des marques officielles partenaires"
  s.is_active = true
  s.position = 9
end

# 10. SHOP SPOTLIGHT - Mise en avant d'une boutique officielle (Sharp | Black Friday)
HomePageSection.find_or_create_by!(section_type: "shop_spotlight") do |s|
  s.title = "Boutiques mises en avant"
  s.description = "Section de mise en avant d'une boutique officielle avec ses produits"
  s.is_active = true
  s.position = 10
end

# =========================================================================
# --- 11. STRUCTURE PAGE BOUTIQUE (par shop) ---
# =========================================================================
# Les sections de page boutique sont créées par shop dans development.rb
# Modèles : ShopPageHeaderSlide, ShopPageSection, ShopPageSectionProduct, ShopPageSectionCategory
# Admin : /admin/shop_page_header_slides, /admin/shop_page_sections, etc.

# 7. PROMO CAROUSEL - Bannière promo avec carousel produits et countdown
promo_carousel_section = HomePageSection.find_or_create_by!(section_type: "promo_carousel") do |s|
  s.title = "Promo Carousel"
  s.description = "Bannière de promotion avec carousel de produits et countdown"
  s.is_active = true
  s.position = 7
end

# Settings par défaut pour promo_carousel
promo_carousel_section.home_page_section_settings.find_or_create_by!(key: "category_label") do |setting|
  setting.value = ""
end
promo_carousel_section.home_page_section_settings.find_or_create_by!(key: "title") do |setting|
  setting.value = ""
end
promo_carousel_section.home_page_section_settings.find_or_create_by!(key: "subtitle") do |setting|
  setting.value = ""
end
promo_carousel_section.home_page_section_settings.find_or_create_by!(key: "discount_text") do |setting|
  setting.value = ""
end
promo_carousel_section.home_page_section_settings.find_or_create_by!(key: "discount_suffix") do |setting|
  setting.value = ""
end
promo_carousel_section.home_page_section_settings.find_or_create_by!(key: "countdown_date") do |setting|
  setting.value = (Date.today + 7.days).to_s
end
promo_carousel_section.home_page_section_settings.find_or_create_by!(key: "shop_id") do |setting|
  setting.value = ""
end
promo_carousel_section.home_page_section_settings.find_or_create_by!(key: "item_ids") do |setting|
  setting.value = ""
end

# 11. RECOMMENDATIONS - Section recommandations
recommendations_section = HomePageSection.find_or_create_by!(section_type: "recommendations") do |s|
  s.title = "Recommandations"
  s.description = "Section de recommandations de produits"
  s.is_active = true
  s.position = 11
end

recommendations_section.home_page_section_settings.find_or_create_by!(key: "title") do |setting|
  setting.value = "Recommandé pour vous"
end
recommendations_section.home_page_section_settings.find_or_create_by!(key: "limit") do |setting|
  setting.value = "12"
end

# 12. NEWSLETTER - Inscription email
newsletter_section = HomePageSection.find_or_create_by!(section_type: "newsletter") do |s|
  s.title = "Newsletter"
  s.description = "Section d'inscription à la newsletter"
  s.is_active = true
  s.position = 12
end

newsletter_section.home_page_section_settings.find_or_create_by!(key: "title") do |setting|
  setting.value = "Restez informé"
end
newsletter_section.home_page_section_settings.find_or_create_by!(key: "subtitle") do |setting|
  setting.value = "Recevez nos meilleures offres et nouveautés"
end
newsletter_section.home_page_section_settings.find_or_create_by!(key: "placeholder") do |setting|
  setting.value = "Votre adresse email"
end
newsletter_section.home_page_section_settings.find_or_create_by!(key: "button_text") do |setting|
  setting.value = "S'abonner"
end

puts "✅ Structure des sections de la page d'accueil créée (12 sections)"
