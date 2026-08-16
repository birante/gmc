#!/usr/bin/env ruby
# Script de débogage pour analyser le problème d'affichage des produits dans le dashboard

puts "🔍 Analyse du problème d'affichage des produits dans le dashboard\n\n"

# Trouver un vendor
vendor = Vendor.first
unless vendor
  puts "❌ Aucun vendor trouvé dans la base de données"
  exit
end

puts "✅ Vendor trouvé: #{vendor.email} (ID: #{vendor.id})"

# Trouver ses boutiques
shops = vendor.shops
puts "\n📦 Boutiques du vendor: #{shops.count}"
shops.each do |shop|
  puts "  - #{shop.name} (ID: #{shop.id}, slug: #{shop.slug})"
end

# Prendre la première boutique
current_shop = shops.first
unless current_shop
  puts "\n❌ Aucune boutique trouvée pour ce vendor"
  exit
end

puts "\n🏪 Boutique sélectionnée: #{current_shop.name} (ID: #{current_shop.id})"

# Simuler les variables du dashboard
shop_condition = "shops.id = ?"
shop_value = current_shop.id

puts "\n🔧 Variables du dashboard:"
puts "  - shop_condition: #{shop_condition}"
puts "  - shop_value: #{shop_value}"

# Tous les produits de la boutique (méthode directe)
puts "\n📊 Produits de la boutique (méthode directe):"
direct_items = Item.where(shop_id: current_shop.id).order(created_at: :desc)
puts "  - Nombre total: #{direct_items.count}"
direct_items.limit(5).each do |item|
  puts "    • #{item.name} (ID: #{item.id}, shop_id: #{item.shop_id}, created_at: #{item.created_at})"
end

# Produits avec la méthode du dashboard (avec joins)
puts "\n📊 Produits de la boutique (méthode dashboard avec joins):"
dashboard_items = Item.joins(:shop)
                      .where(shop_condition, shop_value)
                      .includes(:product_sub_category, :currency, :shop, :variants)
                      .order(created_at: :desc)
                      .limit(8)

puts "  - Nombre: #{dashboard_items.count}"
puts "  - SQL: #{dashboard_items.to_sql}"

dashboard_items.each do |item|
  puts "    • #{item.name} (ID: #{item.id}, shop_id: #{item.shop_id})"
  puts "      - has default_variant: #{item.default_variant.present?}"
  puts "      - variants count: #{item.variants.count}"
  puts "      - product_sub_category: #{item.product_sub_category.name}"
end

# Vérifier si @recent_items serait vide
puts "\n✨ Résultat final:"
if dashboard_items.present?
  puts "  ✅ @recent_items.present? = true"
  puts "  ✅ Les produits DEVRAIENT apparaître dans le dashboard"
else
  puts "  ❌ @recent_items.present? = false"
  puts "  ❌ Aucun produit ne sera affiché dans le dashboard"
end

# Vérifier les variantes
puts "\n🔍 Analyse des variantes:"
direct_items.limit(5).each do |item|
  puts "  Produit: #{item.name} (ID: #{item.id})"
  puts "    - Nombre de variantes: #{item.variants.count}"
  if item.default_variant
    puts "    - Variante par défaut: ✅ (ID: #{item.default_variant.id}, price: #{item.default_variant.price})"
  else
    puts "    - Variante par défaut: ❌ MANQUANTE"
  end
end
