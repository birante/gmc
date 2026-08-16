namespace :homepage do
  desc "Reorganize sections positions"
  task reorganize_positions: :environment do
    # Mettre à jour les positions des sections
    promo = HomePageSection.find_by(section_type: "promo_carousel")
    local = HomePageSection.find_by(section_type: "local_shops")
    official = HomePageSection.find_by(section_type: "official_brands")
    recommendations = HomePageSection.find_by(section_type: "recommendations")
    newsletter = HomePageSection.find_by(section_type: "newsletter")

    puts "📋 Positions AVANT :"
    puts "   Local Shops: #{local&.position}"
    puts "   Official Brands: #{official&.position}"
    puts "   Promo Carousel: #{promo&.position}"
    puts "   Recommendations: #{recommendations&.position}"
    puts "   Newsletter: #{newsletter&.position}"

    # Nouvelles positions
    local&.update!(position: 7)
    official&.update!(position: 8)
    promo&.update!(position: 9)
    recommendations&.update!(position: 10)
    newsletter&.update!(position: 11)

    puts "\n📋 Positions APRÈS :"
    puts "   Local Shops: #{local&.position}"
    puts "   Official Brands: #{official&.position}"
    puts "   Promo Carousel: #{promo&.position}"
    puts "   Recommendations: #{recommendations&.position}"
    puts "   Newsletter: #{newsletter&.position}"

    Rails.cache.clear
    puts "\n✅ Cache vidé - Promo Carousel maintenant après Official Brands"
  end

  desc "Configure promo carousel with an official shop"
  task configure_promo: :environment do
    official_shops = Shop.where(shop_type: "official").includes(:items)

    puts "🏪 Boutiques officielles disponibles :"
    official_shops.each do |shop|
      items_count = shop.items.available_for_sale.count
      puts "  - #{shop.name} (ID: #{shop.id}) - #{items_count} produits"
    end

    shop = official_shops.find { |s| s.items.available_for_sale.any? }

    if shop
      puts "\n✅ Boutique sélectionnée : #{shop.name}"
      items = shop.items.available_for_sale.limit(8)
      item_ids = items.pluck(:id)

      puts "   Produits (#{items.count}) :"
      items.each { |item| puts "     - #{item.name} (ID: #{item.id})" }

      promo_section = HomePageSection.find_by(section_type: "promo_carousel")

      # Mettre à jour shop_id
      shop_setting = promo_section.home_page_section_settings.find_or_initialize_by(key: "shop_id")
      shop_setting.value = shop.id.to_s
      shop_setting.save!

      # Mettre à jour item_ids
      items_setting = promo_section.home_page_section_settings.find_or_initialize_by(key: "item_ids")
      items_setting.value = item_ids.join(", ")
      items_setting.save!

      # Mettre à jour le titre
      title_setting = promo_section.home_page_section_settings.find_or_initialize_by(key: "title")
      title_setting.value = shop.name
      title_setting.save!

      puts "\n✅ Configuration mise à jour"
      puts "   - Boutique : #{shop.name} (#{shop.id})"
      puts "   - Produits : #{item_ids.join(", ")}"

      Rails.cache.clear
      puts "\n✅ Cache vidé - Section maintenant visible sur http://localhost:3000/"
    else
      puts "\n❌ Aucune boutique officielle avec produits trouvée"
      puts "\nBoutiques officielles existantes :"
      Shop.where(shop_type: "official").each do |s|
        puts "  - #{s.name} (ID: #{s.id})"
      end
    end
  end
end
