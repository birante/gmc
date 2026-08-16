# lib/tasks/solid_queue.rake
# Tâches pour gérer le schéma SolidQueue

namespace :db do
  namespace :queue do
    desc "Load the queue database schema"
    task schema: :environment do
      queue_schema_path = Rails.root.join("db", "queue_schema.rb")

      if File.exist?(queue_schema_path)
        puts "📦 Chargement du schéma SolidQueue..."
        begin
          # Charger le schéma dans le contexte de la base de données principale
          ActiveRecord::Base.connection.execute("SET search_path TO public;") if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
          load queue_schema_path
          puts "✅ Schéma SolidQueue chargé avec succès"
        rescue => e
          puts "❌ Erreur lors du chargement du schéma SolidQueue: #{e.message}"
          puts e.backtrace.first(5).join("\n")
        end
      else
        puts "⚠️  Fichier queue_schema.rb introuvable"
      end
    end

    desc "Check if SolidQueue tables exist"
    task check: :environment do
      if ActiveRecord::Base.connection.table_exists?("solid_queue_jobs")
        puts "✅ Les tables SolidQueue existent"
      else
        puts "❌ Les tables SolidQueue n'existent pas"
        puts "   Exécutez: rails db:queue:schema"
      end
    end
  end

  # Surcharger db:reset pour inclure le schéma de queue
  Rake::Task["db:reset"].enhance do
    if Rails.env.development?
      puts ""
      puts "📦 Chargement automatique du schéma SolidQueue..."
      Rake::Task["db:queue:schema"].invoke
    end
  end

  # Surcharger db:schema:load pour inclure le schéma de queue
  Rake::Task["db:schema:load"].enhance do
    if Rails.env.development?
      puts ""
      puts "📦 Chargement automatique du schéma SolidQueue..."
      Rake::Task["db:queue:schema"].invoke
    end
  end
end
