# frozen_string_literal: true

namespace :analytics do
  desc "Nettoyer les données analytics de plus de 2 ans (RGPD)"
  task cleanup: :environment do
    puts "🧹 Nettoyage des données analytics..."

    cutoff_date = 2.years.ago
    total_visits = 0
    total_events = 0

    puts "📅 Suppression des données avant: #{cutoff_date.strftime('%d/%m/%Y %H:%M')}"

    # Supprimer les visites et événements par batch
    Ahoy::Visit.where("started_at < ?", cutoff_date).find_in_batches(batch_size: 1000) do |visits|
      visit_ids = visits.map(&:id)

      # Supprimer les événements liés
      events_count = Ahoy::Event.where(visit_id: visit_ids).delete_all
      total_events += events_count

      # Supprimer les visites
      visits_count = Ahoy::Visit.where(id: visit_ids).delete_all
      total_visits += visits_count

      print "."
    end

    puts "\n"
    puts "✅ Nettoyage terminé!"
    puts "   - #{total_visits} visites supprimées"
    puts "   - #{total_events} événements supprimés"
  end

  desc "Nettoyer les données d'un utilisateur spécifique (RGPD - Droit à l'oubli)"
  task :cleanup_user, [ :user_id ] => :environment do |_task, args|
    if args[:user_id].blank?
      puts "❌ Erreur: Vous devez fournir un user_id"
      puts "Usage: rails analytics:cleanup_user[123]"
      exit 1
    end

    user_id = args[:user_id].to_i
    puts "🧹 Suppression des données pour l'utilisateur ##{user_id}..."

    # Trouver toutes les visites de l'utilisateur
    visit_ids = Ahoy::Visit.where(user_id: user_id).pluck(:id)

    # Supprimer les événements liés aux visites
    events_from_visits = Ahoy::Event.where(visit_id: visit_ids).delete_all

    # Supprimer les événements directement liés à l'utilisateur
    events_from_user = Ahoy::Event.where(user_id: user_id).delete_all

    # Supprimer les visites
    visits_deleted = Ahoy::Visit.where(id: visit_ids).delete_all

    total_events = events_from_visits + events_from_user

    puts "✅ Suppression terminée!"
    puts "   - #{visits_deleted} visites supprimées"
    puts "   - #{total_events} événements supprimés"
  end

  desc "Afficher les statistiques de rétention des données"
  task stats: :environment do
    puts "📊 Statistiques Analytics"
    puts "=" * 50

    total_visits = Ahoy::Visit.count
    total_events = Ahoy::Event.count

    puts "Total:"
    puts "  - Visites: #{total_visits.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
    puts "  - Événements: #{total_events.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
    puts ""

    # Par période
    [
      [ "Dernières 24h", 1.day.ago ],
      [ "7 derniers jours", 7.days.ago ],
      [ "30 derniers jours", 30.days.ago ],
      [ "3 derniers mois", 3.months.ago ],
      [ "6 derniers mois", 6.months.ago ],
      [ "1 an", 1.year.ago ],
      [ "2 ans", 2.years.ago ]
    ].each do |label, date|
      visits = Ahoy::Visit.where("started_at >= ?", date).count
      events = Ahoy::Event.where("time >= ?", date).count

      puts "#{label}:"
      puts "  - Visites: #{visits}"
      puts "  - Événements: #{events}"
    end

    puts ""
    puts "Données à nettoyer (> 2 ans):"
    old_visits = Ahoy::Visit.where("started_at < ?", 2.years.ago).count
    puts "  - #{old_visits} visites"

    if old_visits > 0
      puts ""
      puts "💡 Lancez: rails analytics:cleanup"
    end
  end

  desc "Masquer les IPs déjà enregistrées (migration RGPD)"
  task mask_existing_ips: :environment do
    puts "🔒 Masquage des IPs existantes..."

    masked_count = 0

    Ahoy::Visit.where.not(ip: nil).find_each do |visit|
      masked_ip = Ahoy.mask_ip(visit.ip)

      if masked_ip != visit.ip
        visit.update_column(:ip, masked_ip)
        masked_count += 1
        print "." if masked_count % 100 == 0
      end
    end

    puts "\n✅ #{masked_count} IPs masquées"
  end
end
