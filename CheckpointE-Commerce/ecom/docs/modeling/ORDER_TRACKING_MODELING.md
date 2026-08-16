# Modélisation du Suivi de Commande (Order Tracking)

## Vue d'ensemble

Ce document décrit comment le système de suivi de commande est modélisé pour afficher l'historique de suivi aux clients (comme sur la page de suivi de commande).

## Modèles et Relations

### 1. Order (Commande)
```ruby
Order
  - id (numéro de commande, ex: #96459761)
  - status (enum: pending, processing, shipped, partially_delivered, delivered, canceled)
  - departure_date (datetime) - Date de départ réelle
  - estimated_arrival_date (datetime) - Date d'arrivée estimée
  - delivery_address (text)
  - delivery_slot_id (référence au créneau de livraison)
  - created_at (date de création de la commande)
  
  Relations:
    - has_many :order_status_histories
    - has_many :order_items
    - has_many :shop_transactions (pour les finances)
    - belongs_to :user (client)
    - belongs_to :delivery_slot
```

### 2. OrderStatusHistory (Historique de statut)
```ruby
OrderStatusHistory
  - order_id (référence)
  - status (string) - Le statut au moment de cette entrée
  - note (text) - Message descriptif (ex: "Votre commande est en route")
  - changed_by_type (polymorphic) - Qui a changé le statut (User, Vendor, Employee)
  - changed_by_id (polymorphic)
  - location (string, optionnel) - Localisation où le changement a eu lieu
  - created_at (timestamp) - Quand le changement a eu lieu
```

### 3. OrderItem (Articles de la commande)
```ruby
OrderItem
  - delivery_status (enum: pending_shipment, shipped, delivered, failed, returned)
  - Quand delivery_status == 'delivered', déclenche le crédit de la boutique via FinanceManager
```

### 4. ShopTransaction (Transactions financières)
```ruby
ShopTransaction
  - order_id (optionnel) - Lié à la commande si c'est un crédit de vente
  - transaction_type (credit, debit, refund)
  - amount
  - Quand order_item est livré, crée automatiquement une transaction de type 'credit'
```

### 5. Payout (Reversements)
```ruby
Payout
  - shop_id
  - amount
  - status (pending, processing, paid, failed)
  - payout_month, payout_year
  - Contient plusieurs ShopTransaction de type 'credit'
```

## Flux de Suivi

### Création d'une commande
1. Order créée avec status: "pending"
2. `after_create :create_initial_status_history` crée automatiquement une entrée dans OrderStatusHistory

### Changement de statut
1. Le vendeur/admin change le statut (ex: pending → processing)
2. Le contrôleur appelle `@order.update(status: new_status)`
3. Après le update, le contrôleur appelle `@order.track_status_change!(changed_by: vendor/employee/admin)`
4. Cela crée une nouvelle entrée dans OrderStatusHistory avec:
   - Le nouveau statut
   - Le message localisé approprié
   - Qui a fait le changement
   - La date/heure

### Livraison d'un article
1. OrderItem delivery_status passe à "delivered"
2. `after_update :credit_shop_on_delivery` se déclenche
3. FinanceManager.credit_shop_for_order_item crée une ShopTransaction
4. Le solde de la boutique est crédité

## Affichage pour le Client

### Données à afficher (basées sur l'image)

```ruby
# Dans le contrôleur client/orders#show
@order = Order.find_by(id: params[:id]) # ou par slug

# Données principales
- order_number: @order.order_number (#96459761)
- status: @order.status ("shipped" → "Expédié")
- order_date: @order.created_at (19 Déc, 2025)
- departure_date: @order.departure_date_or_estimated (20 Déc, 2025 09:17)
- estimated_arrival: @order.arrival_date_or_estimated (20 Déc, 2025 12:00)
- delivery_address: @order.delivery_address

# Historique complet
@status_history = @order.order_status_histories.ordered
# Affiche:
# - Commande: "20 Déc, 2025 10:02 - Votre commande a été effectuée avec succès"
# - Traitement: "20 Déc, 2025 11:02 - Votre commande est en cours de traitement..."
# - Expédition: "20 Déc, 2025 12:27 - Votre commande est en route"
# - Livré: "20 Déc, 2025 14:27 - Votre commande a été livrée avec succès"

# Informations vendeur
@shops = @order.shops # Toutes les boutiques de la commande

# Articles commandés
@order_items = @order.order_items.includes(:item, :shop, :item_variant)
```

## Barre de progression

La barre de progression peut être calculée à partir du statut actuel:

```ruby
def tracking_steps
  steps = [
    { name: 'Commande', status: 'pending', completed: %w[pending processing shipped partially_delivered delivered].include?(status) },
    { name: 'Traitement', status: 'processing', completed: %w[processing shipped partially_delivered delivered].include?(status) },
    { name: 'Expédition', status: 'shipped', completed: %w[shipped partially_delivered delivered].include?(status) },
    { name: 'Livré', status: 'delivered', completed: status == 'delivered' }
  ]
end
```

## Localisation des messages

Les messages sont définis dans les fichiers de traduction:
- `config/locales/fr/orders.yml` (ou similaire)
- `config/locales/en/orders.yml`

Exemple:
```yaml
fr:
  orders:
    status:
      pending: "En attente"
      processing: "En traitement"
      shipped: "Expédié"
      delivered: "Livré"
      canceled: "Annulé"
    
    status_history:
      pending: "Votre commande a été effectuée avec succès"
      processing: "Votre commande est en cours de traitement par le vendeur"
      shipped: "Votre commande est en route"
      delivered: "Votre commande a été livrée avec succès"
      canceled: "Votre commande a été annulée"
```

## Intégration avec les Finances

Quand un OrderItem passe à "delivered":
1. FinanceManager.credit_shop_for_order_item est appelé
2. Une ShopTransaction de type 'credit' est créée
3. Le solde de la Shop est incrémenté
4. Plus tard, ces transactions seront regroupées dans un Payout mensuel

## Points importants

1. **Traçabilité complète**: Chaque changement de statut est enregistré avec qui et quand
2. **Messages localisés**: Les messages s'adaptent à la langue de l'utilisateur
3. **Calcul automatique des dates**: Si departure_date n'est pas défini, il est calculé
4. **Synchronisation finances**: Les crédits sont automatiques lors de la livraison
5. **Multi-vendeurs**: Une commande peut contenir des articles de plusieurs boutiques
