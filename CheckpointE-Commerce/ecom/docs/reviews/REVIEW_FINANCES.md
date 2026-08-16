# Review du système financier - Vendors

## ✅ Points positifs

1. **Architecture claire** : Séparation des responsabilités avec FinanceManager
2. **Protection contre les doubles crédits** : Vérification via metadata.order_item_id
3. **Transactions atomiques** : Utilisation d'ActiveRecord::Base.transaction
4. **Logging approprié** : Les actions importantes sont loggées
5. **Scopes utiles** : unpaid, credits, debits dans ShopTransaction

## ⚠️ Problèmes identifiés et améliorations suggérées

### 1. FinanceManager - Gestion d'erreurs

**Problème** : Si `increment!` échoue après la création de la transaction, on a une incohérence.

**Solution suggérée** :
```ruby
# Dans credit_shop_for_order_item
ActiveRecord::Base.transaction do
  transaction = ShopTransaction.create!(...)
  order_item.shop.increment!(:balance, amount_to_credit)
  # Si increment! échoue, la transaction sera rollback grâce à la transaction block
end
```

### 2. FinanceManager - Validation des données

**Problème** : Pas de vérification que `order_item.item` existe avant d'accéder à `item.name`.

**Solution suggérée** :
```ruby
description: "Vente de la commande ##{order_item.order.slug} - #{order_item.item&.name || 'Article supprimé'}"
```

### 3. ShopTransaction - Validation amount

**Problème** : Pas de validation pour s'assurer que amount > 0.

**Solution suggérée** :
```ruby
validates :amount, presence: true, numericality: { greater_than: 0 }
```

### 4. FinanceManager - Metadata query

**Problème potentiel** : La requête sur metadata pourrait ne pas fonctionner si metadata est NULL.

**Amélioration** :
```ruby
existing_transaction = ShopTransaction.where(
  shop: order_item.shop,
  order: order_item.order,
  transaction_type: 'credit'
).where("metadata IS NOT NULL AND metadata->>'order_item_id' = ?", order_item.id.to_s).first
```

### 5. Payout - Currency manquante

**Problème** : Dans `process_monthly_payout`, la currency n'est pas définie.

**Solution suggérée** :
```ruby
payout = Payout.create!(
  shop: shop,
  currency: shop.currency,
  amount: total_to_pay,
  ...
)
```

### 6. FinancesController - Duplication de code

**Problème** : La logique pour déterminer shop_ids est dupliquée dans chaque méthode.

**Solution suggérée** : Extraire dans une méthode privée :
```ruby
private

def shop_ids_for_context
  @shop_ids ||= if @current_shop
    [@current_shop.id]
  else
    current_vendor.shops.pluck(:id)
  end
end
```

### 7. OrderItem callback - Double vérification

**Observation** : Le callback vérifie `delivery_status == 'delivered'` alors que la méthode vérifie aussi. C'est redondant mais sûr.

**Amélioration possible** : Simplifier en supprimant la vérification dans le callback puisque la méthode le fait déjà.

### 8. Migration - Down method

**Problème** : La méthode `down` peut échouer si des valeurs NULL existent.

**Solution** : Ajouter une étape pour remplir les valeurs NULL avant de changer la contrainte :
```ruby
def down
  # Remplacer les valeurs NULL par une valeur par défaut
  ShopTransaction.where(order_id: nil).update_all(order_id: 0) # ou une autre valeur
  ShopTransaction.where(payout_id: nil).update_all(payout_id: 0)
  # Ensuite changer la contrainte...
end
```

### 9. Validation de currency dans Payout

**Suggestion** : Ajouter une validation pour s'assurer que la currency existe si elle est présente :
```ruby
validates :currency, presence: true, if: -> { currency_id.present? }
```

### 10. FinanceManager - Commission en constante

**Observation** : La commission est hardcodée. C'est noté dans le commentaire qu'elle devrait être déplacée.

**Suggestion** : Créer un modèle Configuration ou utiliser Rails.configuration pour stocker cette valeur.

## 🔍 Points à tester

1. **Test du callback** : Vérifier qu'un crédit est créé quand delivery_status passe à 'delivered'
2. **Test de la protection** : Vérifier qu'on ne peut pas créditer deux fois le même order_item
3. **Test du payout** : Vérifier que les transactions sont correctement liées au payout
4. **Test des erreurs** : Vérifier le comportement si order_item.item est nil
5. **Test de la migration** : Tester le up et le down

## 📝 Notes générales

- Le code est bien structuré et lisible
- Les noms de variables et méthodes sont clairs
- La documentation dans les commentaires est bonne
- Les validations de base sont présentes mais pourraient être renforcées
- La gestion d'erreurs pourrait être améliorée dans certains cas
