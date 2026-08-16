# frozen_string_literal: true

namespace :pending_registrations do
  desc "Nettoie les inscriptions en attente expirées (plus de 24h)"
  task cleanup_expired: :environment do
    puts "🧹 Nettoyage des inscriptions en attente expirées..."

    count = PendingRegistration.cleanup_expired!(older_than: 24.hours.ago)

    puts "✅ #{count} inscription(s) expirée(s) supprimée(s)"
  end

  desc "Nettoie les inscriptions en attente vérifiées (plus de 1h)"
  task cleanup_verified: :environment do
    puts "🧹 Nettoyage des inscriptions en attente vérifiées..."

    count = PendingRegistration.cleanup_verified!(older_than: 1.hour.ago)

    puts "✅ #{count} inscription(s) vérifiée(s) supprimée(s)"
  end

  desc "Nettoie toutes les inscriptions en attente obsolètes"
  task cleanup: [ :cleanup_expired, :cleanup_verified ] do
    puts "✅ Nettoyage terminé"
  end

  desc "Affiche les statistiques des inscriptions en attente"
  task stats: :environment do
    total = PendingRegistration.count
    active = PendingRegistration.active.count
    expired = PendingRegistration.expired.count
    verified = PendingRegistration.verified.count

    users = PendingRegistration.for_user.count
    vendors = PendingRegistration.for_vendor.count

    puts "\n📊 Statistiques des inscriptions en attente:"
    puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    puts "Total: #{total}"
    puts "  - Actives: #{active}"
    puts "  - Expirées: #{expired}"
    puts "  - Vérifiées: #{verified}"
    puts ""
    puts "Par type:"
    puts "  - Clients (User): #{users}"
    puts "  - Vendeurs (Vendor): #{vendors}"
    puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
  end
end
