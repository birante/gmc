# 📊 Système Analytics - Documentation Complète

## ✅ Ce qui a été mis en place

### 1. **Tracking Automatique sur TOUTES les pages**
- ✅ Concern `Trackable` ajouté à `ApplicationController`
- ✅ Tracking automatique des pages vues (page_viewed)
- ✅ Tracking des boutiques (shop_viewed)
- ✅ Tracking des produits (item_viewed)
- ✅ Tracking des ajouts au panier (item_added_to_cart)
- ✅ Tracking des commandes (order_completed)

### 2. **Dashboard Analytics Admin** (`/admin/analytics`)
- 📊 Statistiques globales de la plateforme
- 📈 Graphiques d'évolution
- 🏪 Top 15 boutiques
- 🏷️ Top 15 produits
- 🌍 Géolocalisation
- 💻 Devices & navigateurs
- 🔗 Sources de trafic

### 3. **Dashboard Analytics Vendors** (`/vendors/shops/:shop_id/analytics`)
#### Onglets disponibles :
- **📈 Vue d'ensemble** : KPIs principaux, taux de conversion, graphiques
- **🏷️ Produits** : Performance détaillée de chaque produit
- **📦 Commandes** : Analyse des commandes et revenus
- **🌐 Trafic** : Sources, devices, navigateurs

#### KPIs affichés :
- Vues boutique + visiteurs uniques
- Vues produits
- Ajouts au panier
- Commandes + revenu
- Taux de conversion (visiteurs → commandes)
- Top 5 produits les plus vus
- Évolution des vues dans le temps

### 4. **Dashboard Analytics Employés** (`/employees/shops/:shop_id/analytics`)
- ✅ Même interface que les vendors
- ✅ Accès limité aux boutiques auxquelles l'employé est assigné
- ✅ Tous les onglets disponibles

## 📡 Routes créées

### Vendors
```ruby
GET /vendors/shops/:shop_id/analytics?tab=overview&start_date=...&end_date=...
GET /vendors/shops/:shop_id/analytics?tab=products
GET /vendors/shops/:shop_id/analytics?tab=orders
GET /vendors/shops/:shop_id/analytics?tab=traffic
```

### Employés
```ruby
GET /employees/shops/:shop_id/analytics?tab=overview&start_date=...&end_date=...
GET /employees/shops/:shop_id/analytics?tab=products
GET /employees/shops/:shop_id/analytics?tab=orders
GET /employees/shops/:shop_id/analytics?tab=traffic
```

### Admin
```ruby
GET /admin/analytics?start_date=...&end_date=...
```

## 🔧 Configuration

### Initializers
- `config/initializers/ahoy.rb` - Configuration Ahoy
- `config/initializers/analytics.rb` - Configuration du système analytics
- `config/initializers/active_admin.rb` - Intégration Chartkick dans ActiveAdmin

### Services
- `app/services/analytics/tracking_service.rb` - Service principal de tracking
- `app/services/analytics/ahoy_tracker.rb` - Intégration Ahoy
- `app/services/analytics/event_definitions.rb` - Définitions des événements

### Controllers
- `app/controllers/concerns/trackable.rb` - Concern pour le tracking automatique
- `app/controllers/vendors/analytics_controller.rb` - Analytics vendors
- `app/controllers/employees/analytics_controller.rb` - Analytics employés

### Modèles
- `app/models/ahoy/visit.rb` - Modèle des visites
- `app/models/ahoy/event.rb` - Modèle des événements

## 📊 Événements trackés automatiquement

### Pages (88 événements au total)
- `page_viewed` - Chaque page visitée
- `shop_viewed` - Boutique visitée
- `item_viewed` - Produit vu
- `item_added_to_cart` - Produit ajouté au panier
- `item_removed_from_cart` - Produit retiré du panier
- `cart_viewed` - Panier consulté
- `checkout_started` - Début du checkout
- `order_completed` - Commande validée
- Et bien d'autres...

### Propriétés trackées
```ruby
{
  page_name: "shops_show",           # Nom de la page
  page_url: "https://...",           # URL complète
  page_referrer: "https://...",      # Referrer
  locale: "fr",                      # Langue
  utm_source: "...",                 # Source UTM
  utm_medium: "...",                 # Medium UTM
  utm_campaign: "...",               # Campagne UTM
  shop_id: 123,                      # ID boutique (si applicable)
  item_id: 456,                      # ID produit (si applicable)
  # etc.
}
```

## 🚀 Comment tester

### 1. Redémarrer le serveur
```bash
# Arrêter le serveur (Ctrl+C)
bin/dev
```

### 2. Naviguer sur le site
- Visitez la page d'accueil
- Visitez des boutiques
- Regardez des produits
- Ajoutez des articles au panier
- Créez une commande

### 3. Consulter les analytics

#### Admin
```
http://localhost:5000/admin/analytics
```

#### Vendor
```
# Connectez-vous comme vendor
# Puis allez sur :
http://localhost:5000/fr/vendors/shops/[SLUG-BOUTIQUE]/analytics
```

#### Employé
```
# Connectez-vous comme employé
# Puis allez sur :
http://localhost:5000/fr/employees/shops/[SLUG-BOUTIQUE]/analytics
```

## 📋 Filtres de dates

Tous les dashboards incluent :
- 📅 Sélecteur de dates (début/fin)
- 🔖 Raccourcis : Aujourd'hui, 7 jours, 30 jours, Ce mois, etc.
- 📊 Graphiques dynamiques selon la période

## 🎨 Interface

### Design
- 🌓 Mode sombre/clair supporté
- 📱 Responsive (mobile, tablet, desktop)
- 📊 Graphiques interactifs (Chart.js via Chartkick)
- 🎨 UI moderne avec Tailwind CSS

### Graphiques utilisés
- **Line charts** : Évolution dans le temps
- **Area charts** : Revenus, commandes
- **Pie/Donut charts** : Répartition (devices, navigateurs, statuts)
- **Column charts** : Comparaisons

## 🔍 Debugging

### Vérifier si les événements sont trackés
```ruby
# Console Rails
rails console

# Voir les derniers événements
Ahoy::Event.order(time: :desc).limit(10)

# Voir les événements page_viewed
Ahoy::Event.where(name: "page_viewed").count

# Voir les propriétés d'un événement
event = Ahoy::Event.last
event.properties
# => { "page_name" => "shops_show", "page_url" => "...", ... }
```

### Vérifier les visites
```ruby
# Voir les dernières visites
Ahoy::Visit.order(started_at: :desc).limit(10)
```

### Forcer un événement de test
```ruby
# Dans la console Rails
Analytics::TrackingService.new.track_page_view("test_page", {
  page_url: "http://test.com",
  test: true
})
```

## ⚠️ Points importants

### 1. **Noms de pages**
Les noms de pages sont stockés dans `properties->>'page_name'`. 
Si vous ne voyez pas de noms, vérifiez :
- Les événements ont bien la propriété `page_name`
- Le tracking automatique fonctionne (`Trackable` dans `ApplicationController`)

### 2. **Shop_id / Item_id**
Pour filtrer par boutique ou produit, utilisez directement les colonnes :
- `shop_id` (colonne directe dans ahoy_events)
- `item_id` (colonne directe dans ahoy_events)

### 3. **Permissions**
- ✅ Admin : Voir TOUT
- ✅ Vendor : Voir seulement SES boutiques
- ✅ Employé : Voir seulement les boutiques où il est assigné

## 🎯 Prochaines étapes recommandées

1. **Ajouter un lien dans la navigation vendor/employee** vers Analytics
2. **Créer des alertes** (ex: baisse du trafic)
3. **Exporter les données** (CSV, PDF)
4. **Ajouter plus de métriques** (temps passé, bounce rate, etc.)
5. **Tracking des conversions** avancées
6. **Intégration avec d'autres services** (Google Analytics, Amplitude, etc.)

## 📞 Support

En cas de problème :
1. Vérifier les logs : `log/development.log`
2. Vérifier la console browser (F12) pour les erreurs JS
3. Vérifier que Chartkick charge bien : présence de graphiques
4. Tester en console Rails les requêtes Ahoy

