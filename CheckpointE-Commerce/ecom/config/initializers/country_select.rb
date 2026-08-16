# Configuration pour country_select
# Afficher les codes pays au lieu des noms complets

# Return a string to customize the text in the <option> tag, `value` attribute will remain unchanged
CountrySelect::FORMATS[:with_alpha2] = lambda do |country|
  "#{country.iso_short_name} (#{country.alpha2})"
end

# Return an array to customize <option> text, `value` and other HTML attributes
CountrySelect::FORMATS[:with_data_attrs] = lambda do |country|
  [
    country.iso_short_name,
    country.alpha2,
    {
      "data-country-code" => country.country_code,
      "data-alpha3" => country.alpha3
    }
  ]
end

# Format personnalisé pour afficher seulement les codes
CountrySelect::FORMATS[:alpha2_only] = lambda do |country|
  [ country.alpha2, country.alpha2 ]
end

# Format personnalisé pour afficher le nom du pays avec l'indicatif téléphonique
CountrySelect::FORMATS[:with_phone_code] = lambda do |country|
  phone_code = country.country_code.present? ? "+#{country.country_code}" : ""
  display_text = phone_code.present? ? "#{country.iso_short_name} (#{phone_code})" : country.iso_short_name
  [ display_text, country.alpha2 ]
end
