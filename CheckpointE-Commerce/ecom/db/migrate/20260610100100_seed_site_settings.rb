class SeedSiteSettings < ActiveRecord::Migration[8.0]
  DEFAULTS = [
    {
      key: "seo.home.title",
      label: "Page d'accueil — Titre SEO",
      description: "Apparaît dans l'onglet du navigateur et comme titre dans les résultats Google.",
      kind: "text",
      position: 10,
      value_fr: "Marketplace e-commerce au Sénégal - aa",
      value_en: "E-commerce marketplace in Senegal - aa"
    },
    {
      key: "seo.home.description",
      label: "Page d'accueil — Méta description",
      description: "Le court paragraphe qui apparaît sous le titre dans les résultats Google.",
      kind: "textarea",
      position: 20,
      value_fr: "aa, marketplace sénégalaise : boutiques locales, marques officielles, livraison rapide à Dakar et au Sénégal.",
      value_en: "aa, the Senegalese marketplace: local shops, official brands, fast delivery in Dakar and across Senegal."
    },
    {
      key: "seo.home.keywords",
      label: "Page d'accueil — Mots-clés",
      description: "Liste de mots-clés séparés par des virgules. Peu utilisé par Google mais conservé pour d'autres moteurs.",
      kind: "text",
      position: 30,
      value_fr: "aa, e-commerce sénégal, marketplace dakar, boutiques locales, made in senegal, samsung sénégal, livraison dakar",
      value_en: "aa, senegal e-commerce, dakar marketplace, local shops, made in senegal, samsung senegal, dakar delivery"
    }
  ].freeze

  def up
    DEFAULTS.each do |attrs|
      next if SiteSetting.exists?(key: attrs[:key])
      SiteSetting.create!(attrs)
    end
  end

  def down
    SiteSetting.where(key: DEFAULTS.map { |a| a[:key] }).delete_all
  end
end
