# db/seeds.rb
# Fichier principal qui charge les seeds selon l'environnement

puts "🌱 === CHARGEMENT DES SEEDS ==="
puts "Environnement: #{Rails.env}"
puts ""

# Charger le schéma SolidQueue avant les seeds (développement uniquement)
if Rails.env.development? && !ActiveRecord::Base.connection.table_exists?("solid_queue_jobs")
  queue_schema_path = Rails.root.join("db", "queue_schema.rb")
  if File.exist?(queue_schema_path)
    puts ""
    puts "📦 Chargement du schéma SolidQueue..."
    load queue_schema_path
    puts "✅ Schéma SolidQueue chargé"
  end
end

# Charger les seeds selon l'environnement
case Rails.env
when 'development'
  puts "Chargement des seeds développement..."
  load Rails.root.join('db', 'seeds', 'development.rb')
when 'production'
  puts "Chargement des seeds production..."
  load Rails.root.join('db', 'seeds', 'production.rb')
end

puts ""
puts "✅ === CHARGEMENT TERMINÉ ==="
puts ""
