# 🎯 Architecture Rules & Capabilities

Architecture pour gérer les règles (plans, overrides, add-ons) de manière propre et scalable.

## 📐 Structure

```
Controllers / Jobs
        ↓
   Business Guards (Policies)
        ↓
   Capabilities (Facade métier)
        ↓
   RuleResolver / AddOnResolver (Services)
        ↓
   Database (Rules / PlanRules / ShopRules / AddOns)
```

## 🧩 Composants

### 1. `RuleResolver` - Résolution des règles

Service technique qui résout les règles selon la hiérarchie :
- **Priorité 1** : `ShopRule` (override boutique)
- **Priorité 2** : `PlanRule` (via l'abonnement actif)
- **Priorité 3** : `Rule.default_value` (valeur par défaut)

```ruby
resolver = Rules::RuleResolver.new(shop)
max_products = resolver.value("max_products") # nil = illimité
enabled = resolver.enabled?("order_management") # true/false
```

### 2. `AddOnResolver` - Gestion des add-ons

Service pour résoudre les add-ons actifs :

```ruby
addon_resolver = Rules::AddOnResolver.new(shop)
extra_days = addon_resolver.extra_meta_days
express = addon_resolver.express_delivery?
```

### 3. `ShopCapabilities` - Facade métier

Traduit les règles techniques en langage métier :

```ruby
capabilities = shop.capabilities

# Produits
capabilities.can_create_product?(shop.items.count)
capabilities.max_products # nil = illimité

# Commandes
capabilities.order_management?
capabilities.aa_delivery?
capabilities.delivery_express?

# Utilisateurs
capabilities.can_add_employee?(shop.employees.count)
capabilities.multi_users?

# Marketing
capabilities.meta_campaign_days # plan + add-ons
capabilities.analytics_level # "standard", "advanced", "pro"

# IA & Support
capabilities.ai_level # "basic", "full", "premium"
capabilities.support_level # "standard", "priority", "premium"
```

### 4. Intégration dans `Shop`

```ruby
shop.capabilities.can_create_product?(shop.items.count)
```

### 5. Policies - Autorisations

```ruby
policy = ItemPolicy.new(user, item)
policy.create? # vérifie les limites via capabilities
policy.manage_orders? # vérifie order_management
```

### 6. Services - Cas d'usage

```ruby
service = Items::CreateItem.new(shop: shop, params: params)
result = service.call
if result.success?
  # produit créé
else
  # gérer les erreurs (ex: limite atteinte)
end
```

## 🔄 Hiérarchie de résolution

1. **ShopRule** (is_active: true) → Override boutique
2. **PlanRule** (via subscription active) → Règle du plan
3. **Rule.default_value** → Valeur par défaut

## 💡 Gestion de l'illimité

Pour les règles de type `integer` :
- `nil` = illimité
- `10` = limite de 10
- `false` = désactivé

## 🚀 Exemples d'utilisation

### Dans un contrôleur

```ruby
def create
  unless current_shop.capabilities.can_create_product?(current_shop.items.count)
    redirect_to items_path, alert: "Limite de produits atteinte"
    return
  end

  # créer le produit
end
```

### Dans un service

```ruby
def call
  return error("Limite atteinte") unless shop.capabilities.can_create_product?(shop.items.count)
  # logique métier
end
```

### Dans une vue

```erb
<% if shop.capabilities.order_management? %>
  <%= link_to "Gérer les commandes", orders_path %>
<% end %>

<% if shop.capabilities.delivery_express? %>
  <span class="badge">Livraison Express</span>
<% end %>
```

## 🧪 Tests

```ruby
# Test du resolver
resolver = Rules::RuleResolver.new(shop)
expect(resolver.value("max_products")).to eq(nil)

# Test des capabilities
capabilities = shop.capabilities
expect(capabilities.can_create_product?(50)).to be(true)
expect(capabilities.order_management?).to be(true)
```

## 📝 Notes

- Les capabilities sont mis en cache par instance (`@capabilities ||=`)
- Le resolver ne fait pas de cache (peut être ajouté avec Redis si besoin)
- Les add-ons sont résolus dynamiquement (vérification des dates)
- Toutes les méthodes retournent des valeurs explicites (pas de `if plan ==`)

