#!/usr/bin/env rails runner

puts "Vérification des sections avec produits:"
puts ""

sections = [
  { type: "shop_spotlight", name: "Shop Spotlight" },
  { type: "promo_carousel", name: "Promo Carousel" },
  { type: "local_shops_made_in_senegal", name: "Local Shops Made in Senegal" },
  { type: "recommendations", name: "Recommendations" },
  { type: "trending_categories", name: "Trending Categories" }
]

sections.each do |section|
  s = HomePageSection.find_by(section_type: section[:type])
  if s
    product_count = case section[:type]
    when "shop_spotlight"
                      s.shop_spotlights.flat_map(&:items).count
    when "trending_categories"
                      s.home_page_section_groups.flat_map { |g| g.home_page_section_group_items }.count
    else
                      s.home_page_section_products.count
    end
    puts "  - #{section[:name]}: #{product_count} produits"
  else
    puts "  - #{section[:name]}: NOT FOUND"
  end
end

puts ""
puts "Vérification des bannières avec images:"
puts "  - Hero Sliders: #{HeroSliderSlide.count} slides"
puts "  - Promo Banners: #{PromoBanner.count} banners"
puts "  - Secondary Banners: #{SecondaryBanner.count} banners"
puts "  - Official Brand Banners: #{OfficialBrandBanner.count} banners"
puts "  - Local Shop Banners: #{LocalShopBanner.count} banners"
