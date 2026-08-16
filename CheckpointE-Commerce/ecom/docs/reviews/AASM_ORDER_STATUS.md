# Migration vers AASM pour les Statuts de Commande

## ✅ Changements Effectués

### 1. Modèle Order

**Avant** : Utilisation d'un simple `enum :status`

**Après** : Utilisation d'AASM (Acts As State Machine) avec :
- États définis : `pending`, `processing`, `shipped`, `delivered`, `canceled`
- Événements : `process!`, `ship!`, `deliver!`, `cancel!`
- Transitions validées automatiquement
- Callbacks pour créer l'historique automatiquement

### 2. Transitions Autorisées

```
pending → processing (via process!)
pending → shipped (via ship!)
processing → shipped (via ship!)
processing → delivered (via deliver!)
shipped → delivered (via deliver!)
pending → canceled (via cancel!)
processing → canceled (via cancel!)
shipped → canceled (via cancel!)
```

**Note** : Une fois `delivered`, on ne peut plus changer de statut.

### 3. Méthodes Disponibles

AASM génère automatiquement :
- `order.pending?`, `order.processing?`, `order.shipped?`, `order.delivered?`, `order.canceled?`
- `order.status` (retourne la valeur de la colonne, toujours accessible)
- `order.process!`, `order.ship!`, `order.deliver!`, `order.cancel!` (événements avec sauvegarde)
- `order.process`, `order.ship`, `order.deliver`, `order.cancel` (événements sans sauvegarde)
- `order.may_process?`, `order.may_ship?`, etc. (vérifier si la transition est possible)

### 4. Méthode Helper Créée

```ruby
order.update_status!(new_status, changed_by: vendor, note: nil)
```

Cette méthode :
- Mappe le nom du statut vers l'événement AASM approprié
- Définit `current_status_changer` pour les callbacks
- Appelle l'événement AASM (avec validation automatique)
- Crée l'historique via les callbacks AASM

### 5. Contrôleurs Modifiés

Tous les contrôleurs utilisent maintenant `update_status!` au lieu de `update(status: ...)` :
- `Vendors::OrdersController#update_status`
- `Employees::OrdersController#update_status`
- `PaydunyaCallbacksController#cancel`
- `Admin::OrdersController#update_status`
- `PaymentServices::PaydunyaService` (deux endroits)

### 6. Historique Automatique

Les callbacks AASM créent automatiquement les entrées dans `OrderStatusHistory` :
- `after: :create_status_history_entry` pour process, deliver, cancel
- `after: :create_status_history_entry_and_set_departure_date` pour ship

## 🔄 Compatibilité

### Ce qui fonctionne toujours

1. **`order.status`** : Retourne toujours la valeur de la colonne (string)
2. **`.where(status: "...")`** : Fonctionne toujours car AASM stocke dans la colonne
3. **`order.pending?`, etc.** : Méthodes générées automatiquement par AASM
4. **Vues** : Toutes les vues utilisant `order.status` continuent de fonctionner

### Ce qui a changé

1. **Changement de statut** : Doit utiliser `update_status!` ou les événements AASM directement
2. **Validation** : Les transitions invalides sont maintenant bloquées automatiquement
3. **Historique** : Créé automatiquement via les callbacks AASM

## 📝 Exemples d'Utilisation

### Changer le statut (recommandé)

```ruby
# Depuis un contrôleur
order.update_status!("processing", changed_by: current_vendor)

# Ou directement avec les événements AASM
order.current_status_changer = current_vendor
order.process!
```

### Vérifier si une transition est possible

```ruby
if order.may_ship?
  order.ship!
end
```

### Vérifier l'état actuel

```ruby
order.pending?      # => true/false
order.processing?   # => true/false
order.status        # => "pending" (string)
order.aasm.current_state # => :pending (symbol)
```

## ⚠️ Points d'Attention

1. **Retour à pending** : Impossible, car il n'y a pas d'événement pour ça (logique métier)
2. **Delivered est final** : Une fois livré, on ne peut plus changer le statut
3. **Callbacks** : `current_status_changer` doit être défini avant l'événement pour que l'historique fonctionne
4. **Transitions invalides** : Retournent `false` avec `whiny_transitions: false` (pas d'exception)

## 🎯 Avantages

1. **Validation automatique** : Impossible de faire des transitions invalides
2. **Historique automatique** : Plus besoin de créer manuellement l'historique
3. **Code plus propre** : Logique de transition centralisée
4. **Documentation implicite** : Les transitions possibles sont visibles dans le code
5. **Callbacks puissants** : Possibilité d'ajouter facilement des callbacks avant/après transitions
