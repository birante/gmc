#!/usr/bin/env rails runner

puts "Vérification détaillée de la section Local Shops:"
section = HomePageSection.find_by(section_type: "local_shops")
if section
  products = section.home_page_section_products
  puts "  - Section trouvée"
  puts "  - Produits associés: #{products.count}"
  products.each do |p|
    puts "    - #{p.item.name} (#{p.position})"
  end
else
  puts "  - Section NOT FOUND"
end

puts ""
puts "Sections disponibles:"
HomePageSection.all.pluck(:section_type).sort.each do |type|
  puts "  - #{type}"
end
