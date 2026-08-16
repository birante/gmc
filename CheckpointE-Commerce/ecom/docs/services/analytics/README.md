# 📊 Système d'Analytics aa

Documentation complète du système d'analytics pour tracker les utilisateurs (Clients, Vendeurs, Employés).

## 📋 Table des Matières

- [Installation Rapide](#-installation-rapide)
- [Configuration](#-configuration)
- [Architecture](#-architecture)
- [Utilisation](#-utilisation)
- [Événements](#-événements)
- [Interface Admin](#-interface-admin)
- [Tracking Multi-Utilisateurs](#-tracking-multi-utilisateurs)
- [Amplitude](#-amplitude-optionnel)
- [Dépannage](#-dépannage)

---

## 🚀 Installation Rapide

### 1. Installer les gems

```bash
bundle install
```

**Gems installées:**
- `ahoy_matey` - Analytics first-party (base de données)
- `groupdate` - Groupement de dates pour graphiques
- `httparty` - HTTP client pour Amplitude API
- `chartkick` - Graphiques

### 2. Exécuter les migrations

```bash
rails db:migrate
```

**Tables créées:**
- `ahoy_visits` - Visites des utilisateurs
- `ahoy_events` - Événements trackés
- Colonnes `views_count` sur `shops` et `items`

### 3. Vérifier

```bash
rails console
```

```ruby
# Vérifier la configuration
Analytics.configuration.trackers
# => {ahoy: true, amplitude: false, google_analytics: false}

# Vérifier les tables
Ahoy::Visit.count
Ahoy::Event.count
```

### 4. Accéder à l'interface admin

Visitez: `/admin/analytics`

✅ **C'est tout ! Ahoy est maintenant actif.**

---

## 🔧 Configuration

### Configuration par Défaut

```
✅ AHOY - Activé (Analytics en base de données)
❌ AMPLITUDE - Désactivé
❌ GOOGLE ANALYTICS - Désactivé
```

### Variables d'Environnement

**1. Copiez le fichier d'exemple:**

```bash
# À la racine du projet
cp env.example .env
```

**2. Modifiez le `.env` selon vos besoins:**

```bash
# .env

# Système global
ANALYTICS_ENABLED=true          # Active/désactive tout (défaut: true)

# Trackers individuels
AHOY_ENABLED=true              # Ahoy (défaut: true)
AMPLITUDE_ENABLED=false        # Amplitude (défaut: false)
AMPLITUDE_API_KEY=             # Clé API Amplitude
GA_ENABLED=false               # Google Analytics (défaut: false)
GA_MEASUREMENT_ID=             # Measurement ID GA4
```

**3. Redémarrez le serveur:**

```bash
rails restart
```

### Activer la Géolocalisation (Optionnel)

Ahoy peut détecter automatiquement le **pays, région, ville** via l'IP.

**1. Installer le gem geocoder:**

```ruby
# Gemfile
gem 'geocoder'
```

```bash
bundle install
```

**2. Activer dans la configuration:**

```ruby
# config/initializers/ahoy.rb
Ahoy.geocode = true
```

**3. Redémarrer le serveur**

Les visites auront maintenant:
- `country` - Pays (ex: "Senegal")
- `region` - Région (ex: "Dakar")
- `city` - Ville (ex: "Dakar")
- `latitude` / `longitude` - Coordonnées

**Alternative avec CDN/Proxy:**

Si vous utilisez Cloudflare, CloudFront, etc., ils fournissent déjà la géolocalisation via headers:

```ruby
# config/initializers/ahoy.rb
class Ahoy::Store < Ahoy::DatabaseStore
  def track_visit(data)
    # Cloudflare
    data[:country] = request.headers["CF-IPCountry"]
    
    # CloudFront
    # data[:country] = request.headers["CloudFront-Viewer-Country"]
    # data[:region] = request.headers["CloudFront-Viewer-Country-Region"]
    
    super(data)
  end
end
```

**Avantages:**
- ✅ Pas besoin du gem geocoder
- ✅ Plus rapide (pas d'appel API)
- ✅ Plus précis

### Activer Amplitude (Optionnel)

```bash
# .env
AMPLITUDE_ENABLED=true
AMPLITUDE_API_KEY=votre_cle_amplitude_ici
```

**Récupérer la clé API:**
1. Créez un compte sur [amplitude.com](https://amplitude.com)
2. Créez un projet
3. Allez dans Settings → Project → API Key

### Vérifier la Configuration

```ruby
rails console

Analytics.enabled?
# => true

Analytics.configuration.tracker_enabled?(:ahoy)
# => true

Analytics.configuration.tracker_enabled?(:amplitude)
# => false (sauf si activé)
```

Au démarrage en développement, vous verrez:

```
📊 Analytics Configuration:
  - System enabled: true
  - Ahoy: ✅
  - Amplitude: ❌
  - Google Analytics: ❌
```

---

## 📐 Architecture

### Structure des Fichiers

```
app/services/analytics/
├── README.md ⭐               # Ce fichier
├── event_definitions.rb       # Constantes d'événements
├── tracking_service.rb        # Service principal
├── ahoy_tracker.rb           # Tracker Ahoy
├── amplitude_tracker.rb      # Tracker Amplitude
└── google_analytics_tracker.rb

app/controllers/concerns/
└── trackable.rb              # Concern pour auto-tracking

app/models/ahoy/
├── visit.rb                  # Modèle des visites
└── event.rb                  # Modèle des événements

app/admin/
├── analytics.rb              # Interface admin analytics
├── shops.rb                  # Section analytics ajoutée
└── items.rb                  # Section analytics ajoutée

config/initializers/
├── analytics.rb              # Configuration
└── ahoy.rb                   # Configuration Ahoy
```

### Flux de Données

```
1. Utilisateur visite une page
   ↓
2. Concern Trackable capture la requête
   ↓
3. TrackingService reçoit l'événement
   ↓
4. Dispatche vers les trackers activés:
   ├─→ AhoyTracker → Base de données (ahoy_events)
   ├─→ AmplitudeTracker → API Amplitude (si activé)
   └─→ GoogleAnalyticsTracker → GA4 (si activé)
   ↓
5. Données disponibles dans:
   ├─→ /admin/analytics (Ahoy)
   └─→ analytics.amplitude.com (Amplitude)
```

---

## 💻 Utilisation

### Tracking Automatique

Ajoutez le concern `Trackable` à vos contrôleurs:

```ruby
class Client::ShopsController < ApplicationController
  include Trackable  # ✅ Ajouter cette ligne
  
  def show
    @shop = Shop.find(params[:id])
    # La page est automatiquement trackée
  end
end
```

### Tracking Manuel

```ruby
class Client::ShopsController < ApplicationController
  include Trackable
  
  def show
    @shop = Shop.find(params[:id])
    
    # Tracker la vue de boutique
    analytics.track_shop_view(@shop, {
      source: params[:source],
      campaign: params[:campaign]
    })
  end
end
```

### Méthodes Disponibles

```ruby
# Dans un contrôleur avec Trackable inclus

# Pages
analytics.track_page_view(page_name, properties)

# Boutiques
analytics.track_shop_view(shop, properties)
analytics.track_shop_search(query, results_count:, properties:)

# Produits
analytics.track_item_view(item, properties)
analytics.track_item_search(query, results_count:, properties:)

# Panier
analytics.track_add_to_cart(item, quantity:, properties:)
analytics.track_remove_from_cart(item, quantity:, properties:)

# Checkout
analytics.track_checkout_started(cart, properties)
analytics.track_order_completed(order, properties)

# Événement personnalisé
analytics.track_event(event_name, properties)
```

### Exemple Complet

```ruby
class Client::CartItemsController < ApplicationController
  include Trackable
  
  def create
    @item = Item.find(params[:item_id])
    @cart_item = current_cart.add_item(@item, quantity: params[:quantity])
    
    # Tracker l'ajout au panier
    analytics.track_add_to_cart(@item,
      quantity: params[:quantity],
      cart_total: current_cart.total,
      cart_items_count: current_cart.cart_items.count
    )
    
    redirect_to cart_path, notice: "Produit ajouté"
  end
end
```

---

## 📊 Événements

### Constantes Disponibles

Tous les événements sont définis dans `event_definitions.rb`:

#### Navigation
```ruby
Analytics::EventDefinitions::Events::PAGE_VIEWED
Analytics::EventDefinitions::Events::SHOP_VIEWED
Analytics::EventDefinitions::Events::ITEM_VIEWED
```

#### E-commerce
```ruby
Analytics::EventDefinitions::Events::ITEM_ADDED_TO_CART
Analytics::EventDefinitions::Events::ITEM_REMOVED_FROM_CART
Analytics::EventDefinitions::Events::CHECKOUT_STARTED
Analytics::EventDefinitions::Events::ORDER_COMPLETED
```

#### Vendeur
```ruby
Analytics::EventDefinitions::Events::VENDOR_SHOP_CREATED
Analytics::EventDefinitions::Events::VENDOR_PRODUCT_CREATED
Analytics::EventDefinitions::Events::VENDOR_PRODUCT_UPDATED
Analytics::EventDefinitions::Events::VENDOR_ORDER_PROCESSED
```

#### Employé
```ruby
Analytics::EventDefinitions::Events::EMPLOYEE_SHOP_ACCESSED
Analytics::EventDefinitions::Events::EMPLOYEE_ORDER_MANAGED
Analytics::EventDefinitions::Events::EMPLOYEE_PRODUCT_MANAGED
```

#### Client
```ruby
Analytics::EventDefinitions::Events::CLIENT_PROFILE_UPDATED
Analytics::EventDefinitions::Events::CLIENT_ADDRESS_ADDED
Analytics::EventDefinitions::Events::CLIENT_ORDER_TRACKED
```

### Ajouter un Nouvel Événement

1. **Définir la constante:**

```ruby
# app/services/analytics/event_definitions.rb
module Events
  MY_NEW_EVENT = "my_new_event"
end
```

2. **Utiliser:**

```ruby
analytics.track_event(Events::MY_NEW_EVENT, {
  custom_property: "value"
})
```

---

## 🎛️ Interface Admin

### Page Analytics Globale

**URL:** `/admin/analytics`

**Fonctionnalités:**
- ✅ Filtres de dates (début et fin)
- ✅ Raccourcis: Aujourd'hui, 7j, 30j, Ce mois, Mois dernier
- ✅ Statistiques globales
- ✅ Graphiques d'évolution
- ✅ Top 20 pages les plus visitées
- ✅ Top 20 boutiques les plus visitées
- ✅ Top 30 produits les plus vus
- ✅ Répartition des événements
- ✅ Sources de trafic (UTM)
- ✅ Appareils et navigateurs
- ✅ Localisation (pays)

### Analytics par Boutique

**URL:** `/admin/shops/:id` (section Analytics)

**Données:**
- Vues totales
- Vues sur période
- Visiteurs uniques
- Taux de conversion
- Graphique d'évolution
- Top 10 produits de la boutique

### Analytics par Produit

**URL:** `/admin/items/:id` (section Analytics)

**Données:**
- Vues totales
- Vues sur période
- Visiteurs uniques
- Ajouts au panier
- Taux d'ajout au panier
- Graphique d'évolution

---

## 👥 Tracking Multi-Utilisateurs

Le système distingue 3 types d'utilisateurs avec des propriétés spécifiques:

### 🛍️ Clients (User)

**Propriétés envoyées:**
```json
{
  "user_type": "User",
  "user_role": "client",
  "email": "client@example.com",
  "is_premium": false,
  "total_orders": 5,
  "lifetime_value": 234.50
}
```

**Événements spécifiques:**
- `client_profile_updated`
- `client_address_added`
- `client_order_tracked`

**Exemple:**

```ruby
class Client::UsersController < ApplicationController
  include Trackable
  
  def update
    changes = @user.changes
    
    if @user.update(user_params)
      analytics.track_client_profile_updated(@user, changes)
      redirect_to profile_path
    end
  end
end
```

### 🏪 Vendeurs (Vendor)

**Propriétés envoyées:**
```json
{
  "user_type": "Vendor",
  "user_role": "vendor",
  "email": "vendor@example.com",
  "vendor_status": "active",
  "has_shop": true,
  "shop_id": 123,
  "shop_name": "Ma Boutique",
  "total_products": 25
}
```

**Événements spécifiques:**
- `vendor_shop_created`
- `vendor_product_created/updated/deleted`
- `vendor_order_viewed/processed`
- `vendor_dashboard_viewed`

**Exemple:**

```ruby
class Vendors::ItemsController < ApplicationController
  include Trackable
  
  def create
    @item = current_vendor.shop.items.build(item_params)
    
    if @item.save
      analytics.track_vendor_product_created(@item, {
        has_images: @item.images.attached?,
        variants_count: @item.variants.count
      })
      redirect_to vendors_items_path
    end
  end
end
```

### 👔 Employés (Employee)

**Propriétés envoyées:**
```json
{
  "user_type": "Employee",
  "user_role": "employee",
  "email": "employee@example.com",
  "employee_role": "manager",
  "shops_count": 3,
  "shop_ids": [1, 2, 3]
}
```

**Événements spécifiques:**
- `employee_shop_accessed`
- `employee_order_managed`
- `employee_product_managed`

**Exemple:**

```ruby
class Employees::ItemsController < ApplicationController
  include Trackable
  
  def approve
    @item = accessible_items.find(params[:id])
    
    if @item.update(validation_status: "approved")
      analytics.track_employee_product_managed(current_employee, @item,
        action: "approved"
      )
      redirect_to employees_items_path
    end
  end
end
```

---

## 🔵 Amplitude (Optionnel)

### Pourquoi Utiliser Amplitude ?

**Ahoy (inclus):**
- ✅ Gratuit et illimité
- ✅ Données en local (RGPD)
- ✅ Interface admin simple
- ❌ Pas de dashboards avancés

**Amplitude (optionnel):**
- ✅ Dashboards puissants
- ✅ Funnels, cohorts, retention
- ✅ Segmentation avancée
- ✅ Gratuit jusqu'à 10M events/mois
- ❌ Données externes

### Activation

```bash
# .env
AMPLITUDE_ENABLED=true
AMPLITUDE_API_KEY=votre_cle_api_ici
```

### Différence Analytics vs Experiment

**⚠️ Important:**

- **Amplitude Analytics** = Tracking d'événements (ce que nous utilisons)
- **Amplitude Experiment** = Feature flags et A/B testing (séparé)

Nous utilisons l'**HTTP API V2** d'Amplitude pour envoyer les événements, pas le gem `amplitude-experiment`.

### Dashboard Amplitude

1. Allez sur [analytics.amplitude.com](https://analytics.amplitude.com)
2. Connectez-vous
3. Sélectionnez votre projet
4. Créez des graphiques, funnels, etc.

### Exemples d'Analyses

**Funnel de conversion:**
```
shop_viewed (100%)
  ↓ -40%
item_viewed (60%)
  ↓ -50%
item_added_to_cart (30%)
  ↓ -33%
checkout_started (20%)
  ↓ -25%
order_completed (15%)
```

**Segmentation:**
- Par type d'utilisateur (client/vendor/employee)
- Par nombre de commandes
- Par valeur du panier
- Par appareil

---

## 🐛 Dépannage

### Les événements ne sont pas trackés

**Vérifier:**

```ruby
rails console

# Le système est-il activé ?
Analytics.enabled?

# Ahoy est-il activé ?
Analytics.configuration.tracker_enabled?(:ahoy)

# Des événements existent-ils ?
Ahoy::Event.count
Ahoy::Event.last
```

**Solutions:**
1. Vérifier que `ANALYTICS_ENABLED=true`
2. Vérifier que `AHOY_ENABLED=true`
3. Vérifier que `Trackable` est inclus dans le contrôleur
4. Redémarrer le serveur

### Les graphiques ne s'affichent pas

**Vérifier:**

```bash
bundle list | grep -E "(chartkick|groupdate)"
```

**Solution:**

```bash
bundle install
rails restart
```

### Amplitude ne reçoit pas les événements

**Vérifier:**

```ruby
Analytics.configuration.tracker_enabled?(:amplitude)
# => true

ENV["AMPLITUDE_API_KEY"]
# => "votre_cle"
```

**Solution:**

```bash
# .env
AMPLITUDE_ENABLED=true
AMPLITUDE_API_KEY=votre_cle_ici
```

Redémarrez le serveur.

### Voir les logs

```bash
# Développement
tail -f log/development.log | grep -E "(Analytics|Ahoy|Amplitude)"

# Console
rails console

# Derniers événements
Ahoy::Event.last(10).each do |e|
  puts "#{e.name} - #{e.time} - #{e.properties}"
end
```

---

## 🔒 RGPD et Confidentialité

Notre configuration Ahoy suit les [recommandations officielles](https://github.com/ankane/ahoy#gdpr-compliance) pour la conformité RGPD :

### Mesures de Protection Activées

```ruby
# config/initializers/ahoy.rb

# ✅ Masquage des IPs
Ahoy.mask_ips = true
# IPv4: 8.8.4.4 → 8.8.4.0
# IPv6: 2001:4860:4860::8844 → 2001:4860:4860::

# ✅ Pas de cookies (anonymity sets)
Ahoy.cookies = :none
# Groupe les visiteurs par: IP masqué + User Agent

# ✅ Pas de bots
Ahoy.track_bots = false
```

### Données Collectées

**Données automatiques:**
- IP masquée (dernier octet à 0)
- User agent (navigateur, OS)
- URL visitée
- Referrer
- Appareil (desktop, mobile, tablet)

**Données NON collectées:**
- IP complète ❌
- Cookies de tracking ❌
- Données personnelles sensibles ❌

### Linking Utilisateurs (Optionnel)

Par défaut, les visites sont **automatiquement liées aux utilisateurs connectés** via `current_user`.

**Pour désactiver** (RGPD strict):

```ruby
# config/initializers/ahoy.rb
class Ahoy::Store < Ahoy::DatabaseStore
  def authenticate(data)
    # Ne fait rien = pas de linking automatique
  end
end
```

### Droit à l'Oubli

Pour supprimer toutes les données d'un utilisateur:

```ruby
# Dans une tâche ou contrôleur
user_id = 123

# Supprimer les événements
visit_ids = Ahoy::Visit.where(user_id: user_id).pluck(:id)
Ahoy::Event.where(visit_id: visit_ids).delete_all
Ahoy::Event.where(user_id: user_id).delete_all

# Supprimer les visites
Ahoy::Visit.where(user_id: user_id).delete_all
```

### Rétention des Données

Supprimez régulièrement les anciennes données:

```ruby
# Supprimer les données de plus de 2 ans
Ahoy::Visit.where("started_at < ?", 2.years.ago).find_in_batches do |visits|
  visit_ids = visits.map(&:id)
  Ahoy::Event.where(visit_id: visit_ids).delete_all
  Ahoy::Visit.where(id: visit_ids).delete_all
end
```

**Recommandation:** Créez une tâche Rake pour automatiser:

```ruby
# lib/tasks/analytics.rake
namespace :analytics do
  desc "Nettoyer les données analytics de plus de 2 ans"
  task cleanup: :environment do
    cutoff = 2.years.ago
    
    Ahoy::Visit.where("started_at < ?", cutoff).find_in_batches do |visits|
      visit_ids = visits.map(&:id)
      Ahoy::Event.where(visit_id: visit_ids).delete_all
      Ahoy::Visit.where(id: visit_ids).delete_all
      
      puts "Supprimé #{visits.size} visites"
    end
  end
end
```

**Tâches Rake disponibles:**

```bash
# Nettoyer les données de plus de 2 ans
rails analytics:cleanup

# Supprimer les données d'un utilisateur (droit à l'oubli)
rails analytics:cleanup_user[123]

# Voir les statistiques de rétention
rails analytics:stats

# Masquer les IPs déjà enregistrées (migration RGPD)
rails analytics:mask_existing_ips
```

**Automatiser avec un cron job** (Heroku Scheduler, whenever, etc.):

```bash
# Tous les mois
0 0 1 * * cd /app && rails analytics:cleanup
```

### Politique de Confidentialité

Mentionnez dans votre politique de confidentialité:

> Nous collectons des données analytiques anonymisées pour améliorer nos services :
> - Pages visitées
> - Appareil utilisé (desktop/mobile)
> - Localisation approximative (pays, région)
> - Les adresses IP sont masquées
> - Aucun cookie de tracking n'est utilisé
> - Rétention: 2 ans maximum

### Amplitude et RGPD

Si vous utilisez Amplitude:

```ruby
# app/services/analytics/amplitude_tracker.rb

# Les user_properties sont enrichies mais anonymisables:
def user_properties
  props = {
    user_type: @user.class.name,
    # Pas d'email en clair si RGPD strict
  }
  
  # Anonymiser l'ID si nécessaire
  # user_id = Digest::SHA256.hexdigest(@user.id.to_s)
  
  props
end
```

---

## 📈 Statistiques des Modèles

### Shop

```ruby
shop = Shop.find(1)

# Incrémenter les vues
shop.increment_view_count

# Statistiques
stats = shop.analytics_summary(period: 7.days)
# => {
#   total_views: 1234,
#   recent_views: 56,
#   unique_visitors: 42,
#   top_items: [...],
#   conversion_rate: 2.5
# }

# Vues par jour
daily = shop.daily_views(
  start_date: 1.month.ago.to_date,
  end_date: Date.today
)
# => {"2024-11-01" => 10, "2024-11-02" => 15, ...}
```

### Item

```ruby
item = Item.find(1)

# Incrémenter les vues
item.increment_view_count

# Statistiques
stats = item.analytics_summary(period: 30.days)
# => {
#   total_views: 456,
#   recent_views: 23,
#   unique_visitors: 18,
#   add_to_cart_rate: 15.5,
#   total_added_to_cart: 7
# }

# Vues par jour
daily = item.daily_views(
  start_date: 1.week.ago.to_date,
  end_date: Date.today
)
```

---

## 🔍 Requêtes Utiles

### Événements Ahoy

```ruby
# Événements des 7 derniers jours
Ahoy::Event.recent(7)

# Par type
Ahoy::Event.shop_views.count
Ahoy::Event.item_views.count
Ahoy::Event.cart_actions.count
Ahoy::Event.orders.count

# Pour une boutique
Ahoy::Event.for_shop(shop_id).count

# Dans une période
Ahoy::Event.in_period(7.days.ago, Date.today)

# Par type d'utilisateur
Ahoy::Event.joins(:user)
  .where(users: {type: "Vendor"})
  .where("name LIKE ?", "vendor_%")
  .count
```

### Visites

```ruby
# Visites récentes
Ahoy::Visit.where("started_at >= ?", 7.days.ago)

# Visiteurs uniques
Ahoy::Visit.distinct.count(:visitor_token)

# Par pays
Ahoy::Visit.group(:country).count

# Par appareil
Ahoy::Visit.group(:device_type).count
```

### Requêtes Avancées sur Propriétés

Ahoy fournit des helpers pour requêter les propriétés JSON ([doc officielle](https://github.com/ankane/ahoy#querying-events)):

```ruby
# Requête sur nom + propriétés
Ahoy::Event.where_event("item_viewed", item_id: 123).count

# Requête sur propriétés uniquement
Ahoy::Event.where_props(shop_id: 456).count
Ahoy::Event.where_props(item_id: 123, category: "Books").count

# Grouper par propriété
Ahoy::Event.where(name: "item_viewed")
  .group_prop(:shop_id)
  .count
# => {1 => 50, 2 => 30, 3 => 20}

# Grouper par plusieurs propriétés
Ahoy::Event.where(name: "item_viewed")
  .group_prop(:shop_id, :category)
  .count
# => {[1, "Books"] => 10, [1, "Electronics"] => 40, ...}

# Top 10 boutiques les plus visitées
Ahoy::Event.where(name: "shop_viewed")
  .group_prop(:shop_id)
  .count
  .sort_by { |_, count| -count }
  .first(10)

# Top produits par catégorie
Ahoy::Event.where(name: "item_viewed")
  .where_props(category: "Electronics")
  .group_prop(:item_id)
  .count
  .sort_by { |_, count| -count }
  .first(10)

# Funnels
viewed_shop_ids = Ahoy::Event
  .where(name: "shop_viewed")
  .distinct.pluck(:user_id)

added_cart_ids = Ahoy::Event
  .where(user_id: viewed_shop_ids, name: "item_added_to_cart")
  .distinct.pluck(:user_id)

ordered_ids = Ahoy::Event
  .where(user_id: added_cart_ids, name: "order_completed")
  .distinct.pluck(:user_id)

puts "Funnel:"
puts "  Vus boutique: #{viewed_shop_ids.size}"
puts "  Ajouté panier: #{added_cart_ids.size} (#{(added_cart_ids.size.to_f / viewed_shop_ids.size * 100).round(1)}%)"
puts "  Commandé: #{ordered_ids.size} (#{(ordered_ids.size.to_f / viewed_shop_ids.size * 100).round(1)}%)"
```

**Note:** MySQL et MariaDB retournent toujours des clés en string pour `group_prop`, y compris `"null"` pour `nil`.

---

## ⚙️ Configuration Avancée

### Désactiver le Tracking

```ruby
# config/initializers/analytics.rb
Analytics.configure do |config|
  config.enabled = false  # Désactive tout
end
```

Ou via variable d'environnement:

```bash
ANALYTICS_ENABLED=false
```

### Désactiver un Tracker Spécifique

```bash
# .env
AHOY_ENABLED=false          # Désactive Ahoy
AMPLITUDE_ENABLED=false     # Désactive Amplitude
GA_ENABLED=false            # Désactive GA4
```

### Mode Debug

```ruby
# config/initializers/analytics.rb
Analytics.configure do |config|
  config.debug_mode = true  # Logs verbeux
end
```

### Tracking Asynchrone

```ruby
# config/initializers/analytics.rb
Analytics.configure do |config|
  config.async_tracking = true  # Utilise des jobs
end
```

En production, c'est automatiquement activé.

---

## 🎯 Métriques Clés

### Pour les Clients
- **CAC** - Customer Acquisition Cost
- **LTV** - Lifetime Value
- **Conversion Rate** - % qui achètent
- **Cart Abandonment** - % de paniers abandonnés
- **AOV** - Average Order Value

### Pour les Vendeurs
- **Time to First Sale** - Temps jusqu'à la 1ère vente
- **Product Upload Rate** - Produits ajoutés/jour
- **Order Processing Time** - Temps de traitement
- **Revenue per Vendor** - CA moyen

### Pour les Employés
- **Orders Processed/Day** - Commandes/jour
- **Error Rate** - Taux d'erreur
- **Response Time** - Temps de réponse
- **Feature Adoption** - % utilisant les nouvelles fonctionnalités

---

## 📝 Checklist de Production

Avant de déployer:

- [ ] Gems installées (`bundle install`)
- [ ] Migrations exécutées (`rails db:migrate`)
- [ ] Variables d'environnement configurées
- [ ] Trackable ajouté aux contrôleurs principaux
- [ ] Testé en développement
- [ ] Interface admin accessible (`/admin/analytics`)
- [ ] Amplitude configuré (si utilisé)
- [ ] RGPD - Politique de confidentialité mise à jour

---

## 📞 Support

### Documentation

- **Ce fichier** - Guide complet
- **Code source** - Voir les fichiers dans ce dossier
- **Interface admin** - `/admin/analytics`

### Ressources Externes

- **Ahoy:** [github.com/ankane/ahoy](https://github.com/ankane/ahoy)
- **Amplitude:** [developers.amplitude.com](https://developers.amplitude.com)
- **Chartkick:** [chartkick.com](https://chartkick.com)

---

**Version:** 2.1.0  
**Dernière mise à jour:** 29 Novembre 2024  
**Status:** ✅ Production Ready

**Fichier:** `app/services/analytics/README.md`

