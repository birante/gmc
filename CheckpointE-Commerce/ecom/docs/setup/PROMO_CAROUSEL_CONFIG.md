# Configuration Section Promo Carousel - Sharp Black Friday

## 📋 Vue d'ensemble

La section **Promo Carousel** (position 7 sur la page d'accueil) affiche une grande bannière de promotion avec :
- **Panneau gauche** : Informations de la promotion (label, titre, description, badge réduction, countdown)
- **Panneau droit** : Carousel défilant avec les produits sélectionnés

Cette section est idéale pour mettre en avant une boutique officielle (ex: Sharp) avec des promotions limitées dans le temps (ex: Black Friday).

## 🎯 Fonctionnalités

### 1. Gestion complète via ActiveAdmin

Interface dédiée : `/admin/promo_carousel`

**Champs configurables :**
- ✅ Activation/désactivation de la section
- ✅ Label catégorie (ex: "EN PROMO")
- ✅ Titre principal (ex: "Sharp")
- ✅ Sous-titre/description (ex: "Black Friday - Les meilleures offres de l'année")
- ✅ Texte réduction (ex: "Jusqu'à -50%")
- ✅ Suffixe réduction (ex: "DE RÉDUCTION")
- ✅ Date de fin du countdown
- ✅ Sélection de la boutique officielle
- ✅ Liste des IDs de produits à afficher (séparés par virgules)

### 2. Countdown Timer

Un timer dynamique affiche le temps restant jusqu'à la fin de la promotion :
- Jours
- Heures
- Minutes
- Secondes

Le countdown est géré par un contrôleur Stimulus (`countdown_controller.js`).

### 3. Carousel de produits

Les produits s'affichent dans un carousel horizontal avec :
- Boutons de navigation précédent/suivant
- Défilement automatique si plus de 4 produits
- Responsive (adapté mobile/tablette/desktop)

Le carousel est géré par un contrôleur Stimulus (`promo_carousel_controller.js`).

## 🏗️ Architecture technique

### Modèles impliqués

```ruby
# Section principale
HomePageSection (section_type: "promo_carousel")

# Settings de configuration
HomePageSectionSetting
  - category_label: String
  - title: String
  - subtitle: String
  - discount_text: String
  - discount_suffix: String
  - countdown_date: String (format YYYY-MM-DD)
  - shop_id: String
  - item_ids: String (IDs séparés par virgules)
```

### Service de données

`app/services/pages/home_data_service.rb` charge les données :

```ruby
# Méthodes principales
- cached_promo_carousel_settings  # Charge les settings de configuration
- manual_promo_items              # Charge les produits sélectionnés
- promo_carousel_item_ids         # Parse les IDs de produits depuis settings
```

**Caching** : 
- Settings : 30 minutes
- Produits : 15 minutes
- Cache invalidé automatiquement lors de la mise à jour

### Vues

```
app/views/shared/storefront/_promo_banner_carousel.html.erb
```

La vue s'affiche uniquement si `has_promo_content` est vrai (au moins un setting présent ou des produits).

### Controllers Stimulus

```javascript
// app/javascript/controllers/countdown_controller.js
// Gère le countdown timer dynamique

// app/javascript/controllers/promo_carousel_controller.js
// Gère la navigation du carousel de produits
```

## 📦 Fichiers créés/modifiés

### 1. Seeds

**db/seeds/shared.rb** (lignes 704-742)
- Création de la section `promo_carousel` (position 7)
- Définition des 8 settings par défaut

**db/seeds/development.rb** (après ligne 307)
- Configuration Sharp Black Friday
- Countdown de 10 jours par défaut
- shop_id et item_ids vides (à configurer via admin)

### 2. Interface ActiveAdmin

**app/admin/promo_carousel_configurations.rb** (nouveau fichier)
- Page custom ActiveAdmin
- Formulaire de configuration complet
- Panel d'état actuel avec visualisation
- Action POST pour enregistrer
- Invalidation automatique du cache
- Menu : "Page d'accueil" > "Promo Carousel (Sharp)"

### 3. Service existant

**app/services/pages/home_data_service.rb** (déjà existant)
- Méthodes de caching déjà implémentées
- Pas de modification nécessaire

### 4. Vue existante

**app/views/shared/storefront/_promo_banner_carousel.html.erb** (déjà existant)
- Vue complète déjà implémentée
- Pas de modification nécessaire

### 5. Controller

**app/controllers/pages_controller.rb** (déjà existant)
- Charge déjà @promo_items et @promo_carousel_settings
- Pas de modification nécessaire

## 🚀 Utilisation

### 1. Accéder à l'interface de configuration

1. Se connecter à l'admin : `/admin`
2. Menu : **Page d'accueil** > **Promo Carousel (Sharp)**

### 2. Configurer la promotion

**Étape 1 : Activation**
- Cocher "Section active" pour activer la section

**Étape 2 : Contenu de la promotion**
- Label catégorie : `EN PROMO`
- Titre principal : `Sharp`
- Sous-titre : `Black Friday - Les meilleures offres de l'année`
- Texte réduction : `Jusqu'à -50%`
- Suffixe réduction : `DE RÉDUCTION`

**Étape 3 : Countdown**
- Sélectionner la date de fin de la promotion

**Étape 4 : Boutique et produits**
- Sélectionner une boutique officielle (ex: Sharp)
- Entrer les IDs des produits séparés par virgules (ex: `123, 456, 789`)

**Étape 5 : Enregistrer**
- Cliquer sur "Enregistrer la configuration"
- Le cache est automatiquement vidé

### 3. Vérifier sur la page d'accueil

1. Aller sur `/` ou `/fr`
2. La section apparaît entre **Tendances du moment** et **Boutiques locales**
3. Le countdown affiche le temps restant
4. Les produits sont affichés dans le carousel

### 4. Trouver les IDs de produits

**Méthode 1 : Via l'admin**
1. Aller dans **Catalogue** > **Produits**
2. Ouvrir un produit
3. L'ID est dans l'URL : `/admin/items/123`

**Méthode 2 : Via Rails console**
```ruby
# Trouver tous les produits d'une boutique
Shop.find_by(name: "Sharp").items.pluck(:id, :name)

# Limiter aux produits en promo
Shop.find_by(name: "Sharp").items.where(is_on_sale: true).pluck(:id, :name)
```

## 🔄 Workflow complet

```
1. Créer une boutique officielle Sharp (si pas existante)
   └─> /admin/shops/new
   └─> Cocher "Boutique officielle"

2. Créer des produits pour Sharp
   └─> /admin/items/new
   └─> Sélectionner boutique Sharp
   └─> Ajouter images, prix, variantes

3. Configurer la promo carousel
   └─> /admin/promo_carousel
   └─> Remplir tous les champs
   └─> Entrer les IDs des produits Sharp
   └─> Définir la date de fin
   └─> Activer la section

4. Vérifier sur la page d'accueil
   └─> /fr
   └─> La section s'affiche en position 7

5. Désactiver après la promo
   └─> /admin/promo_carousel
   └─> Décocher "Section active"
```

## ⚙️ Configuration avancée

### Changer l'image de fond

L'image de fond est statique :
```ruby
# app/views/shared/storefront/_promo_banner_carousel.html.erb
# Ligne ~43
<%= image_tag "storefront/promo/promo-bg.jpg", ... %>
```

Pour la changer :
1. Ajouter une nouvelle image dans `app/assets/images/storefront/promo/`
2. Modifier le chemin dans la vue
3. Ou ajouter un champ `background_image` dans les settings

### Ajouter une image produit promo

Actuellement, le champ `image` dans les settings n'est pas utilisé. Pour l'activer :

1. Ajouter un champ file upload dans le formulaire admin
2. Utiliser Active Storage pour attacher l'image
3. La vue affichera automatiquement l'image si présente

### Limiter le nombre de produits

Le carousel fonctionne bien avec 6-12 produits. Au-delà, le défilement peut être moins fluide.

**Recommandation** : 8-10 produits maximum.

## 🎨 Personnalisation visuelle

### Couleurs

La bannière utilise un fond violet : `bg-[#551694]`

Pour changer :
```erb
<!-- app/views/shared/storefront/_promo_banner_carousel.html.erb -->
<div class="relative bg-[#551694] ...">
  <!-- Remplacer par la couleur souhaitée -->
  <div class="relative bg-[#FF0000] ...">
```

### Dimensions

- Desktop : `h-[485px]`
- Mobile : hauteur automatique
- Panneau gauche : `w-[250px]` sur desktop

## 📊 Métriques & Analytics

À implémenter :
- Tracking des clics sur les produits du carousel
- Tracking de la conversion de la promo
- Nombre de vues de la section

## 🐛 Dépannage

### La section ne s'affiche pas

**Vérifications :**
1. Section active ? → `/admin/promo_carousel`
2. Au moins un setting rempli ? → Vérifier category_label, title ou countdown_date
3. Cache vidé ? → `Rails.cache.clear`
4. Position correcte ? → Position = 7

### Le countdown ne fonctionne pas

**Vérifications :**
1. Date valide ? → Format YYYY-MM-DD
2. Date dans le futur ? → Si date passée, le countdown affiche 00:00:00:00
3. Stimulus chargé ? → Vérifier la console navigateur

### Les produits ne s'affichent pas

**Vérifications :**
1. IDs valides ? → Vérifier dans `/admin/items`
2. Produits disponibles ? → `Item.find(123).available_for_sale?`
3. Produits avec images ? → Vérifier main_image attachée
4. Variantes existantes ? → Chaque produit doit avoir au moins une variante

### Changements non visibles

**Solution :**
```ruby
# Via rails console
Rails.cache.clear

# Ou via l'admin après enregistrement (automatique)
```

## 📝 Notes importantes

### Cache

- Settings : cache de 30 minutes
- Produits : cache de 15 minutes
- Le cache est automatiquement invalidé lors de la modification via l'admin

### Performance

- Eager loading des associations (shop, currency, variants, images)
- Sélection limitée des colonnes nécessaires
- Caching agressif pour réduire les requêtes DB

### Sécurité

- Seuls les produits `available_for_sale` sont affichés
- Les IDs invalides sont automatiquement filtrés
- La section peut être désactivée instantanément

## 🔗 Liens utiles

- Interface admin : `/admin/promo_carousel`
- Page d'accueil : `/fr`
- Sections HP : `/admin/home_page_sections`
- Settings HP : `/admin/home_page_section_settings`
- Boutiques : `/admin/shops`
- Produits : `/admin/items`

## 📅 Historique

**2026-02-12** : Création initiale de la section Promo Carousel
- Section créée dans `db/seeds/shared.rb` (position 7)
- Interface ActiveAdmin créée (`promo_carousel_configurations.rb`)
- Configuration Sharp Black Friday ajoutée dans `development.rb`
- Documentation complète
