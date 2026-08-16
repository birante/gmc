namespace :shops do
  desc "Recolle shops.available_items_count à partir du vrai nombre d'items approuvés"
  task recompute_available_items_counts: :environment do
    before = Shop.pluck(:id, :available_items_count).to_h
    Shop.recompute_all_available_items_counts!
    after = Shop.pluck(:id, :available_items_count).to_h

    drift = before.each_with_object([]) do |(id, old), acc|
      new = after[id]
      acc << [ id, old, new ] if old != new
    end

    if drift.empty?
      puts "✅ Aucun compteur à corriger."
    else
      puts "🔧 #{drift.size} boutique(s) corrigée(s):"
      drift.each { |id, old, new| puts "  shop ##{id}: #{old} → #{new}" }
    end
  end
end
