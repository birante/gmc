# Structure des Seeds - Page d'Accueil

## 📁 Organisation des fichiers

La configuration de la page d'accueil est maintenant organisée en deux parties distinctes :

### 1. `db/seeds/shared.rb` - Structure des sections (Partagé)

**Contenu :** Structure des 11 sections de la page d'accueil  
**Environnements :** Development, Production, Test (tous)  
**Sections créées :**
- Marquee (bandeau animé)
- Hero Slider (carousel principal)
- Promo Banners (4 bannières)
- Categories (catégories populaires)
- Secondary Banners
- Trending Categories (tendances)
- Local Shops (boutiques locales)
- Official Brands (marques officielles)
- Recommendations
- Newsletter

**Ce qui est créé :** Uniquement la structure `HomePageSection` avec titre, description, position et statut actif. Aucune donnée de test.

### 2. `db/seeds/development.rb` - Données de test (Development uniquement)

**Contenu :** Données de test intégrées directement dans le fichier  
**Environnement :** Development uniquement  
**Données créées :**

#### Trending Categories
- 4 groupes (Casque Audio, Smart watch, Airpods, Enceinte connectée)
- 4 items par groupe (grille 4×4)
- Total : 16 items

#### Local Shops
- 7 bannières de boutiques locales (Cindera, Cam, Flore, Delices, Sab Bio, Sunu Sabou, Teaways)
- Avec images attachées depuis `app/assets/images/storefront/local-shops/banners/`

#### Made in Senegal
- 1 bannière latérale (titre, sous-titre, description, CTA, couleurs, image)
- 6 produits sélectionnés automatiquement (`origin_country: "SN"`)

#### Official Brands
- 6 marques officielles (Samsung, Hisense, Sharp, Oraimo, Legrand, Roch)
- Avec logos attachés depuis `app/assets/images/storefront/official-brands/`

## 🔄 Flux d'exécution

### Development
```ruby
# db/seeds/development.rb
load 'db/seeds/shared.rb'      # Structure des sections (section 1)
# Données de test homepage (section 1B - inline)
# Vendors, boutiques, produits... (section 2+)
```

### Production
```ruby
# db/seeds/production.rb
load 'db/seeds/shared.rb'      # Structure des sections uniquement
# Pas de données de test - tout se gère via ActiveAdmin
```

## 📝 Avantages de cette organisation

1. **Simplicité** : Toutes les données de test dans un seul fichier (development.rb)
2. **Séparation claire** : Structure (shared) vs Données de test (development)
3. **Réutilisabilité** : La structure est partagée entre tous les environnements
4. **Flexibilité** : En production, pas de données de test - tout via ActiveAdmin
5. **Maintenance** : Plus facile de trouver et modifier les données de test
6. **Performance** : En production, seed plus rapide (pas de données inutiles)

## 🎯 Gestion via ActiveAdmin

Toutes ces données sont modifiables via l'interface d'administration :

- **Tendances** : `/admin/home_page_section_groups` + `/admin/home_page_section_group_items`
- **Made in Senegal (Bannière)** : `/admin/home_page_section_side_banners`
- **Made in Senegal (Produits)** : `/admin/home_page_section_products`
- **Boutiques locales** : `/admin/local_shop_banners`
- **Boutiques officielles** : `/admin/official_brand_banners`

## 🚀 Commandes utiles

```bash
# Exécuter tous les seeds (development)
rails db:seed

# Exécuter uniquement la structure (tous environnements)
rails runner "load 'db/seeds/shared.rb'"

# Vider le cache après modification
rails runner 'Rails.cache.clear'
```

## 📌 Fichiers

- ✅ `db/seeds/shared.rb` - Structure des sections (partagé)
- ✅ `db/seeds/development.rb` - Données de test intégrées (développement)
- 🗄️ `db/seeds/homepage.rb.old` - Ancien fichier (à supprimer)
- ❌ `db/seeds/homepage_data.rb` - Supprimé (intégré dans development.rb)
