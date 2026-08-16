# Review des Statuts de Commande

## 📋 Vue d'ensemble

Le système de statuts fonctionne à deux niveaux :
1. **Order.status** : Statut global de la commande
2. **OrderItem.delivery_status** : Statut de livraison de chaque article

## ✅ Points Positifs

### 1. Architecture à deux niveaux
- **Order.status** : Gère le statut global (pending, processing, shipped, delivered, canceled)
- **OrderItem.delivery_status** : Permet de gérer chaque article individuellement (pending_shipment, shipped, delivered, failed, returned)
- Cette approche est **correcte** car une commande peut contenir plusieurs articles de différentes boutiques

### 2. Historique complet
- `OrderStatusHistory` enregistre tous les changements de statut
- Traçabilité de qui a fait le changement (polymorphic changed_by)
- Messages localisés pour chaque statut

### 3. Callbacks bien structurés
- `after_create :create_initial_status_history` pour l'historique initial
- `after_update :credit_shop_on_delivery` pour le crédit automatique

## ⚠️ Problèmes Identifiés

### 1. ❌ **MANQUE : Synchronisation automatique Order ↔ OrderItems**

**Problème** : Quand tous les OrderItems sont livrés (`delivered`), le statut de l'Order devrait automatiquement passer à `delivered` (ou `partially_delivered` si certains sont livrés).

**Code actuel** :
- Quand un OrderItem passe à `delivered`, seul `credit_shop_on_delivery` est appelé
- Aucune logique pour vérifier si tous les articles sont livrés et mettre à jour l'Order.status

**Solution suggérée** :
```ruby
# Dans OrderItem, après credit_shop_on_delivery
after_update :update_order_status_if_needed, if: -> { saved_change_to_delivery_status? }

private

def update_order_status_if_needed
  return unless delivery_status == 'delivered'
  
  # Vérifier si tous les articles sont livrés
  all_items = order.order_items
  delivered_items = all_items.where(delivery_status: 'delivered')
  failed_items = all_items.where(delivery_status: 'failed')
  
  if delivered_items.count == all_items.count
    # Tous livrés
    order.update(status: 'delivered') if order.status != 'delivered'
  elsif delivered_items.count > 0 && (delivered_items.count + failed_items.count) < all_items.count
    # Partiellement livré
    order.update(status: 'partially_delivered') if order.status != 'partially_delivered'
  end
end
```

### 2. ⚠️ **Pas de validation des transitions de statut**

**Problème** : Un vendeur peut passer directement de `pending` à `delivered` sans passer par `processing` et `shipped`, ce qui est incohérent.

**Solution suggérée** :
```ruby
# Dans Order model
validate :status_transition_valid

private

def status_transition_valid
  return unless status_changed?
  
  valid_transitions = {
    'pending' => ['processing', 'canceled'],
    'processing' => ['shipped', 'partially_delivered', 'canceled'],
    'shipped' => ['partially_delivered', 'delivered', 'canceled'],
    'partially_delivered' => ['delivered'],
    'delivered' => [], # État final
    'canceled' => [] # État final
  }
  
  old_status = status_was || status
  unless valid_transitions[old_status]&.include?(status)
    errors.add(:status, "Transition invalide de #{old_status} vers #{status}")
  end
end
```

### 3. ⚠️ **update_column utilisé au lieu de update**

**Problème** : Dans `Vendors::OrdersController#update_status` et `Employees::OrdersController#update_status`, on utilise `update_column(:departure_date, ...)` après le `update(status: ...)`. Cela évite les callbacks, mais c'est acceptable ici car on veut juste mettre à jour la date sans retrigger les validations.

**Cependant**, il serait mieux de faire cela en une seule transaction atomique :
```ruby
if @order && @order.update(status: params[:new_status], departure_date: departure_date_value)
```

### 4. ⚠️ **PaydunyaCallbacksController met à jour le statut sans historique**

**Problème** : Dans `PaydunyaCallbacksController#cancel`, on fait :
```ruby
payment.order.update(status: "canceled")
```
Mais aucun historique n'est créé et aucun `changed_by` n'est défini.

**Solution suggérée** :
```ruby
if payment.order.update(status: "canceled")
  payment.order.track_status_change!(changed_by: nil, note: "Commande annulée suite à l'annulation du paiement")
end
```

### 5. ⚠️ **Employees::OrdersController utilise .where(id:) au lieu de friendly.find**

**Problème** : Dans `Employees::OrdersController#update_status`, on utilise :
```ruby
@order = Order.joins(order_items: :shop)
             .where(id: params[:id])
             .where(shop_condition, shop_value)
             .first
```
Cela ne fonctionnera pas avec les slugs FriendlyId (ex: "2-085c7740-...").

**Solution suggérée** :
```ruby
begin
  @order = Order.friendly.find(params[:id])
rescue ActiveRecord::RecordNotFound
  @order = nil
end

# Ensuite vérifier l'accès comme dans Vendors::OrdersController
```

### 6. ⚠️ **Pas de gestion du statut "partially_delivered"**

**Problème** : Le statut `partially_delivered` existe mais n'est jamais automatiquement défini. Il faudrait une logique pour le déclencher automatiquement quand certains articles sont livrés mais pas tous.

**Solution** : Intégrer dans la solution du point #1.

### 7. ⚠️ **OrderItem : Pas de validation des transitions de delivery_status**

**Problème** : On peut passer de `delivered` à `pending_shipment`, ce qui n'a pas de sens logique.

**Solution suggérée** :
```ruby
# Dans OrderItem model
validate :delivery_status_transition_valid

private

def delivery_status_transition_valid
  return unless delivery_status_changed?
  
  # Une fois livré, on ne peut que le retourner ou le marquer comme échoué
  if delivery_status_was == 'delivered' && !['returned', 'failed'].include?(delivery_status)
    errors.add(:delivery_status, "Un article livré ne peut pas revenir à #{delivery_status}")
  end
end
```

### 8. ⚠️ **Méthode track_status_change! peut échouer silencieusement**

**Problème** : Dans les contrôleurs, on appelle `track_status_change!` après `update`, mais si cela échoue, on ne le sait pas.

**Solution suggérée** :
```ruby
if @order && @order.update(status: params[:new_status])
  begin
    @order.track_status_change!(changed_by: @vendor)
  rescue => e
    Rails.logger.error("❌ Erreur création historique: #{e.message}")
    # Ne pas faire échouer la requête, mais logger l'erreur
  end
  # ...
end
```

Mais en fait, puisque `create!` lève une exception, on devrait peut-être utiliser `create` et logger une erreur si ça échoue plutôt que de faire planter la requête.

### 9. ✅ **Gestion des dates de départ correcte**

**Point positif** : La logique pour définir `departure_date` quand le statut passe à `shipped` est correcte.

## 🔄 Flux Recommandé

### Flux normal d'une commande :
```
1. Création → Order.status = 'pending'
   └─> OrderStatusHistory créé automatiquement

2. Vendeur commence le traitement → Order.status = 'processing'
   └─> track_status_change!(changed_by: vendor)
   
3. Vendeur expédie → Order.status = 'shipped'
   └─> track_status_change!(changed_by: vendor)
   └─> departure_date = Time.current (si nil)

4. Livraison d'un article → OrderItem.delivery_status = 'delivered'
   └─> credit_shop_on_delivery (crédite la boutique)
   └─> Si tous les articles sont livrés → Order.status = 'delivered'
   └─> Si seulement quelques articles → Order.status = 'partially_delivered'
   └─> track_status_change! pour l'Order si changement
```

## 📝 Recommandations Prioritaires

### 🔴 **Priorité Haute** :

1. **Ajouter la synchronisation automatique Order ↔ OrderItems** (Point #1)
   - Impact : Fonctionnalité manquante importante
   - Effort : Moyen

2. **Corriger Employees::OrdersController pour utiliser friendly.find** (Point #5)
   - Impact : Bug fonctionnel
   - Effort : Faible

3. **Ajouter l'historique dans PaydunyaCallbacksController** (Point #4)
   - Impact : Traçabilité incomplète
   - Effort : Faible

### 🟡 **Priorité Moyenne** :

4. **Valider les transitions de statut** (Points #2 et #7)
   - Impact : Améliore l'intégrité des données
   - Effort : Moyen

5. **Améliorer la gestion d'erreur de track_status_change!** (Point #8)
   - Impact : Robustesse
   - Effort : Faible

### 🟢 **Priorité Basse** :

6. **Optimiser l'update de departure_date** (Point #3)
   - Impact : Code plus propre
   - Effort : Faible

## 📊 Tableau de Cohérence

| Order.status | OrderItems (tous) | OrderItems (partiel) | Cohérence |
|-------------|-------------------|----------------------|-----------|
| pending | pending_shipment | - | ✅ OK |
| processing | pending_shipment/shipped | - | ✅ OK |
| shipped | shipped/delivered | - | ✅ OK |
| partially_delivered | Mix delivered/other | - | ⚠️ Pas auto |
| delivered | delivered | - | ⚠️ Pas auto |
| canceled | any | - | ✅ OK |

## 🎯 Conclusion

Le système de statuts est bien structuré mais manque de logique automatique pour synchroniser Order.status avec OrderItem.delivery_status. Les validations de transition amélioreraient également l'intégrité des données.

**Actions immédiates recommandées** :
1. Implémenter la synchronisation automatique (Point #1)
2. Corriger le friendly.find dans Employees::OrdersController (Point #5)
3. Ajouter l'historique dans PaydunyaCallbacksController (Point #4)
