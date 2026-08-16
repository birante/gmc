#!/usr/bin/env ruby
# Script pour activer PayDunya sur les boutiques
# Usage: rails runner activate_paydunya.rb

puts "🔧 Activation de PayDunya pour les boutiques"
puts "=" * 60

# Trouver la méthode de paiement PayDunya
paydunya_method = PaymentMethod.find_by(code: 'paydunya')

if paydunya_method.nil?
  puts "❌ Méthode de paiement PayDunya non trouvée"
  puts "   Exécutez: rails db:seed"
  exit 1
end

puts "\n✅ Méthode PayDunya trouvée"
puts "   ID: #{paydunya_method.id}"
puts "   Nom: #{paydunya_method.name}"
puts "   Active: #{paydunya_method.is_active}"

# Lister toutes les boutiques
shops = Shop.all
puts "\n📊 #{shops.count} boutique(s) trouvée(s)"

shops.each do |shop|
  # Vérifier si la boutique a déjà PayDunya
  existing = ShopPaymentMethod.find_by(shop: shop, payment_method: paydunya_method)

  if existing
    puts "  ⏭️  #{shop.name} - PayDunya déjà activé"
  else
    ShopPaymentMethod.create!(
      shop: shop,
      payment_method: paydunya_method,
      is_active: true
    )
    puts "  ✅ #{shop.name} - PayDunya activé"
  end
end

puts "\n" + "=" * 60
puts "✅ PayDunya activé sur toutes les boutiques !"
puts ""
