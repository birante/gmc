# db/seeds/production.rb
# Seeds pour la production - Données essentielles pour le go-live
# Objectif : créer toutes les données nécessaires pour que l'application fonctionne en production

puts "🚀 === SEEDS PRODUCTION ==="
puts "Création des données essentielles pour le go-live..."
puts ""

# Charger les seeds partagées (données essentielles communes)
load Rails.root.join('db', 'seeds', 'shared.rb')

puts ""
puts "✅ === SEEDS PRODUCTION TERMINÉES ==="
