# db/seeds/development.rb
# Seeds pour le développement - Données essentielles + utilisateurs de test + produits
# Objectif : données complètes pour développer et tester l'application
#
# OPTIMISATIONS:
# - Section MARQUEE: plus de textes défilants. La bannière est maintenant pilotée par une image
#   uploadée via ActiveAdmin (marquee_image). Les home_page_section_items sont vidés systématiquement.
# - Variables: utilise seed_references[:key] pour toutes les données de référence partagées

puts "🌱 === SEEDS DÉVELOPPEMENT ==="
puts "Création de toutes les données essentielles pour le développement..."
puts ""

# =========================================================================
# --- 1. CHARGEMENT DES SEEDS PARTAGÉES ---
# =========================================================================

# Charger les seeds partagées (données essentielles communes)
# Inclut : devises, zones de livraison, moyens de paiement, catégories,
# secteurs, règles, admin, et structure des sections de la page d'accueil
load Rails.root.join('db', 'seeds', 'shared.rb')

# =========================================================================
# --- 2. VENDEUR + BOUTIQUE + COLLABORATEURS DE TEST (dev uniquement) ---
# =========================================================================
# Comptes réutilisables pour tester le portail vendeur et l'espace collaborateur.
# Idempotent : find_or_initialize_by sur email, on (re)définit le mot de passe
# à chaque exécution pour garantir un compte utilisable.

puts ""
puts "🧑‍💼 Création du vendeur + boutique + collaborateurs de test..."

DEV_VENDOR_PASSWORD    = "password@2026".freeze
DEV_VENDOR_EMAIL       = "vendeur.test@aa.dev".freeze
DEV_SHOP_NAME          = "Boutique Test Dev".freeze
DEV_EMPLOYEES = [
  { email: "manager.test@aa.dev",  first_name: "Amina", last_name: "Diop",  role: "manager",       phone_number: "770000011", is_primary: true },
  { email: "cashier.test@aa.dev",  first_name: "Mouhamed", last_name: "Ndiaye", role: "cashier",   phone_number: "770000012", is_primary: false },
  { email: "stock.test@aa.dev",    first_name: "Fatou", last_name: "Sarr",   role: "stock_manager", phone_number: "770000013", is_primary: false }
].freeze

vendor = Vendor.find_or_initialize_by(email: DEV_VENDOR_EMAIL)
vendor.first_name    = "Test"
vendor.last_name     = "Vendeur"
vendor.phone_number  = "770000010"
vendor.country_code  = "221"
vendor.password      = DEV_VENDOR_PASSWORD
vendor.status        = "active"
vendor.save!

# Vendor#verified? exige au moins une VendorVerification avec status: true
unless vendor.vendor_verifications.where(status: true).exists?
  vendor.vendor_verifications.create!(
    code:       SecureRandom.hex(3).upcase,
    channel:    "sms",
    expires_at: 1.year.from_now,
    used_at:    Time.current,
    status:     true
  )
end

puts "✅ Vendeur (#{DEV_VENDOR_EMAIL}) — mot de passe: #{DEV_VENDOR_PASSWORD}"

xof = Currency.find_by(code: "XOF")
shop = Shop.find_or_initialize_by(name: DEV_SHOP_NAME)
shop.vendor        = vendor
shop.address       = "Dakar, Sénégal"
shop.description   = "Boutique de test générée par le seed de développement."
shop.status        = "active"
shop.shop_type     = "local"
shop.currency      = xof if xof
shop.primary_color = "#551694"
shop.save!

puts "✅ Boutique « #{shop.name} » (#{shop.slug}) — status: #{shop.status}, currency: #{xof&.code || 'aucune'}"

# Palette de démarrage : les nouvelles boutiques la reçoivent via after_create,
# mais il faut la seeder manuellement pour la boutique dev déjà créée.
if shop.shop_colors.empty?
  shop.send(:seed_default_shop_colors)
  puts "🎨 Palette par défaut ajoutée à la boutique dev (#{shop.shop_colors.count} couleurs)"
end

DEV_EMPLOYEES.each do |attrs|
  employee = Employee.find_or_initialize_by(email: attrs[:email])
  employee.vendor       = vendor
  employee.first_name   = attrs[:first_name]
  employee.last_name    = attrs[:last_name]
  employee.phone_number = attrs[:phone_number]
  employee.country_code = "221"
  employee.role         = attrs[:role]
  employee.status       = "active"
  employee.password     = DEV_VENDOR_PASSWORD
  employee.save!

  link = EmployeeShop.find_or_initialize_by(employee: employee, shop: shop)
  link.is_primary = attrs[:is_primary]
  link.save!

  puts "✅ Collaborateur #{attrs[:role].ljust(14)} (#{attrs[:email]}) — mot de passe: #{DEV_VENDOR_PASSWORD}"
end

puts ""
puts "🔑 Récap des comptes de test :"
puts "   Vendeur      → #{DEV_VENDOR_EMAIL} / #{DEV_VENDOR_PASSWORD}"
DEV_EMPLOYEES.each { |a| puts "   Collab #{a[:role].ljust(14)} → #{a[:email]} / #{DEV_VENDOR_PASSWORD}" }
puts ""
