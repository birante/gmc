#!/usr/bin/env rails runner

puts "HeroSliderSlides avec images:"
HeroSliderSlide.all.each do |slide|
  status = slide.image.attached? ? "OK" : "MISSING"
  puts "  - Slide #{slide.position}: #{status}"
end

puts ""
puts "PromoBanners avec images:"
PromoBanner.all.each do |banner|
  status = banner.image.attached? ? "OK" : "MISSING"
  puts "  - Banner #{banner.position}: #{status}"
end

puts ""
puts "SecondaryBanners avec images:"
SecondaryBanner.all.each do |banner|
  status = banner.image.attached? ? "OK" : "MISSING"
  puts "  - Banner #{banner.position_type}: #{status}"
end

puts ""
puts "Produits avec image:"
count_with_image = Item.all.select { |i| i.main_image.attached? }.count
puts "  - #{count_with_image}/#{Item.count} produits ont des images"
