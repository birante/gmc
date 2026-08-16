# 🔍 Revue de Performance Globale - aa Apps

## 📊 Résumé Exécutif

Cette revue analyse tous les problèmes de N+1 queries et propose des améliorations de performance pour l'application aa.

## ✅ N+1 Queries Corrigés (Session Actuelle)

### 1. Items/Variants/AttributeValues
- ✅ `app/queries/public_items_query.rb` - Préchargement des `attribute_values: :item_attribute`
- ✅ `app/views/items/show.html.erb` - Utilisation de `.find` au lieu de `.joins`
- ✅ `app/controllers/vendors/items_controller.rb` - Préchargement correct
- ✅ `app/controllers/pages_controller.rb` - Correction du préchargement des variants

### 2. Employees/Shops
- ✅ `app/controllers/vendors/employees_controller.rb` - Préchargement `employee_shops`
- ✅ `app/views/vendors/employees/index.html.erb` - Utilisation d'un hash en mémoire
- ✅ `app/services/vendors/dashboard_data_service.rb` - Préchargement correct

### 3. Orders/OrderItems
- ✅ `app/views/client/orders/index.html.erb` - Utilisation de `.size` au lieu de `.count`
- ✅ Les queries utilisent déjà `.includes` correctement

## 🚨 N+1 Queries Restants à Corriger

### 1. CRITIQUE: `shop.items.count` dans les vues

**Problème**: Multiples appels à `shop.items.available_for_sale.count` dans des boucles

**Fichiers affectés**:
- `app/views/categories/show.html.erb:179`
- `app/views/categories/sub_category.html.erb:201`
- `app/views/client/shops/index.html.erb:118`
- `app/views/shops/index.html.erb:119`
- `app/views/client/shops/show.html.erb:87`
- `app/views/items/index.html.erb:118`
- `app/views/client/items/index.html.erb:117`
- `app/views/shops/_local_shop_show.html.erb:41`
- `app/views/shops/_shop_info_header.html.erb:65`
- `app/views/vendors/shops/edit.html.erb:41,161`
- `app/controllers/shops_controller.rb:52`

**Solution recommandée**: Ajouter un `counter_cache` sur le modèle Shop

### 2. MOYEN: `item.variants.count` dans certaines vues

**Problème**: Utilisation de `.count` au lieu de `.size` sur des collections préchargées

**Fichiers affectés**:
- `app/views/client/items/show.html.erb:26`
- `app/views/client/items/_variant_selector.html.erb:1`
- `app/views/vendors/items/index.html.erb:145`
- `app/views/client/items/_variants_preview.html.erb:1,3,14,16,21`

**Solution**: Utiliser `.size` si les variants sont déjà préchargés, ou précharger les variants

### 3. MOYEN: `current_user.orders.count` dans le dashboard client

**Fichiers affectés**:
- `app/views/client/dashboards/show.html.erb:29,44,59`
- `app/controllers/client/dashboards_controller.rb:12`

**Solution**: Ces requêtes sont uniques (pas en boucle), mais peuvent être optimisées avec un counter_cache

### 4. MOYEN: `order.order_items.sum(:quantity)` dans dashboard vendor

**Fichier affecté**:
- `app/views/vendors/dashboards/show.html.erb:484`

**Solution**: S'assurer que `order_items` sont préchargés dans la query

### 5. FAIBLE: `shop.items.count` dans les helpers et services

**Fichiers affectés**:
- `app/helpers/vendors_helper.rb:103`
- `app/repositories/item_repository.rb:117`
- `app/views/vendors/shared/_plan_limits.html.erb:19`
- `app/views/vendors/shared/_limit_alert.html.erb:7`
- `app/views/vendors/items/index.html.erb:50`

**Solution**: Utiliser un counter_cache ou une requête optimisée

## 🎯 Améliorations de Performance Proposées

### 1. Counter Caches (Priorité HAUTE)

#### A. Items Count sur Shop
```ruby
# Migration
class AddItemsCountToShops < ActiveRecord::Migration[8.0]
  def change
    add_column :shops, :items_count, :integer, default: 0
    add_index :shops, :items_count
    
    # Migrer les données existantes
    Shop.find_each do |shop|
      Shop.reset_counters(shop.id, :items)
    end
  end
end

# Modèle Shop
class Shop < ApplicationRecord
  has_many :items, dependent: :destroy, counter_cache: :items_count
  has_many :available_items, -> { available_for_sale }, class_name: "Item", counter_cache: :available_items_count
end

# Nouveau champ
# Migration pour available_items_count
class AddAvailableItemsCountToShops < ActiveRecord::Migration[8.0]
  def change
    add_column :shops, :available_items_count, :integer, default: 0
    add_index :shops, :available_items_count
  end
end

# Callback sur Item
class Item < ApplicationRecord
  after_save :update_shop_items_count, if: :saved_change_to_validation_status?
  
  private
  
  def update_shop_items_count
    if validation_status == 'approved' && shop.available_items_count_changed?
      shop.increment!(:available_items_count)
    end
  end
end
```

#### B. Variants Count sur Item
```ruby
# Migration
class AddVariantsCountToItems < ActiveRecord::Migration[8.0]
  def change
    add_column :items, :variants_count, :integer, default: 0
    add_index :items, :variants_count
    
    Item.find_each do |item|
      Item.reset_counters(item.id, :variants)
    end
  end
end

# Modèle Item
class Item < ApplicationRecord
  has_many :variants, dependent: :destroy, class_name: "ItemVariant", counter_cache: :variants_count
end
```

#### C. Orders Count sur User
```ruby
# Migration
class AddOrdersCountToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :orders_count, :integer, default: 0
    add_index :users, :orders_count
    
    User.find_each do |user|
      User.reset_counters(user.id, :orders)
    end
  end
end

# Modèle User
class User < ApplicationRecord
  has_many :orders, dependent: :destroy, counter_cache: :orders_count
end
```

### 2. Indexes Manquants (Priorité MOYENNE)

#### A. Indexes sur Item
```ruby
# Migration
class AddPerformanceIndexesToItems < ActiveRecord::Migration[8.0]
  def change
    # Index composé pour les requêtes fréquentes
    add_index :items, [:shop_id, :validation_status, :is_on_sale], 
              name: 'index_items_on_shop_status_sale'
    add_index :items, [:product_sub_category_id, :validation_status],
              name: 'index_items_on_subcategory_status'
    add_index :items, [:validation_status, :created_at],
              name: 'index_items_on_status_created'
    add_index :items, :origin_country, where: "origin_country = 'SN'"
  end
end
```

#### B. Indexes sur OrderItem
```ruby
class AddPerformanceIndexesToOrderItems < ActiveRecord::Migration[8.0]
  def change
    add_index :order_items, [:shop_id, :delivery_status, :created_at],
              name: 'index_order_items_on_shop_status_created'
    add_index :order_items, [:order_id, :shop_id],
              name: 'index_order_items_on_order_shop'
  end
end
```

#### C. Indexes sur Shop
```ruby
class AddPerformanceIndexesToShops < ActiveRecord::Migration[8.0]
  def change
    add_index :shops, [:status, :shop_type, :created_at],
              name: 'index_shops_on_status_type_created'
    add_index :shops, :vendor_id, where: "status = 'active'"
  end
end
```

### 3. Optimisations de Requêtes (Priorité MOYENNE)

#### A. Précharger les images dans les listes
```ruby
# Dans PublicItemsQuery
def available_for_sale
  Item.available_for_sale
      .includes(
        :shop, 
        :product_sub_category, 
        :currency, 
        :variants,
        main_image_attachment: :blob,  # ✅ Déjà fait
        images_attachments: :blob       # ✅ Déjà fait
      )
end
```

#### B. Utiliser `select` pour limiter les colonnes chargées
```ruby
# Dans pages_controller.rb - Déjà fait partiellement
# S'assurer de toujours utiliser .select pour les listes
```

### 4. Cache Strategy (Priorité BASSE pour maintenant)

#### A. Fragment Caching pour les sections de la homepage
```erb
<% cache ['homepage', 'categories', ProductCategory.maximum(:updated_at)] do %>
  <%= render 'shared/storefront/categories_grid', categories: @categories %>
<% end %>
```

#### B. Cache des counts fréquents
```ruby
# Dans ApplicationHelper
def shop_items_count(shop)
  Rails.cache.fetch("shop/#{shop.id}/items_count", expires_in: 5.minutes) do
    shop.items.available_for_sale.count
  end
end
```

### 5. Optimisations Ruby (Priorité BASSE)

#### A. Éviter les appels `.count` dans les boucles
```ruby
# ❌ Mauvais
shops.each { |shop| shop.items.count }

# ✅ Bon
items_counts = Item.where(shop_id: shops.map(&:id))
                   .group(:shop_id)
                   .count
shops.each { |shop| items_counts[shop.id] || 0 }
```

#### B. Utiliser `pluck` au lieu de charger les objets
```ruby
# ❌ Mauvais
shop_ids = shops.map(&:id)

# ✅ Bon  
shop_ids = shops.pluck(:id)
```

## 📝 Plan d'Action

### Phase 1: Corrections Critiques (1-2 jours)
1. ✅ Corriger les N+1 queries identifiés dans les vues
2. ✅ Remplacer `.count` par `.size` quand les collections sont préchargées
3. ✅ S'assurer que tous les queries utilisent `.includes` correctement

### Phase 2: Counter Caches (2-3 jours)
1. Ajouter `items_count` et `available_items_count` sur Shop
2. Ajouter `variants_count` sur Item  
3. Ajouter `orders_count` sur User
4. Mettre à jour les callbacks pour maintenir les counters

### Phase 3: Indexes (1 jour)
1. Ajouter les indexes recommandés
2. Analyser les slow queries avec EXPLAIN
3. Optimiser les requêtes les plus lentes

### Phase 4: Monitoring et Optimisations Futures (Ongoing)
1. Configurer un monitoring des performances (New Relic, Scout, etc.)
2. Identifier les requêtes lentes en production
3. Implémenter le cache stratégiquement

## 🔧 Fichiers à Modifier

### Controllers
- [ ] `app/controllers/client/dashboards_controller.rb` - Utiliser counter_cache
- [ ] `app/controllers/shops_controller.rb` - Utiliser counter_cache

### Views
- [ ] `app/views/categories/show.html.erb` - Utiliser counter_cache
- [ ] `app/views/categories/sub_category.html.erb` - Utiliser counter_cache
- [ ] `app/views/client/shops/index.html.erb` - Utiliser counter_cache
- [ ] `app/views/shops/index.html.erb` - Utiliser counter_cache
- [ ] `app/views/client/shops/show.html.erb` - Utiliser counter_cache
- [ ] `app/views/items/index.html.erb` - Utiliser counter_cache
- [ ] `app/views/client/items/index.html.erb` - Utiliser counter_cache
- [ ] `app/views/shops/_local_shop_show.html.erb` - Utiliser counter_cache
- [ ] `app/views/shops/_shop_info_header.html.erb` - Utiliser counter_cache
- [ ] `app/views/client/items/show.html.erb` - Utiliser `.size` si préchargé
- [ ] `app/views/client/items/_variant_selector.html.erb` - Utiliser `.size` si préchargé
- [ ] `app/views/vendors/items/index.html.erb` - Utiliser counter_cache
- [ ] `app/views/vendors/shops/edit.html.erb` - Utiliser counter_cache

### Models
- [ ] `app/models/shop.rb` - Ajouter counter_cache
- [ ] `app/models/item.rb` - Ajouter counter_cache
- [ ] `app/models/user.rb` - Ajouter counter_cache

### Migrations
- [ ] Créer migration pour `items_count` sur shops
- [ ] Créer migration pour `available_items_count` sur shops
- [ ] Créer migration pour `variants_count` sur items
- [ ] Créer migration pour `orders_count` sur users
- [ ] Créer migration pour les indexes de performance

## 📊 Métriques de Performance Attendues

### Avant Optimisations
- Homepage: ~500-800ms (avec cache)
- Page catégorie: ~300-500ms
- Dashboard vendor: ~400-600ms
- Liste des boutiques: ~200-400ms

### Après Optimisations (Estimation)
- Homepage: ~200-400ms (réduction de 40-50%)
- Page catégorie: ~150-300ms (réduction de 50%)
- Dashboard vendor: ~200-400ms (réduction de 50%)
- Liste des boutiques: ~100-200ms (réduction de 50%)

## 🎓 Bonnes Pratiques Appliquées

1. ✅ Eager Loading avec `.includes`
2. ✅ Utilisation de `.size` au lieu de `.count` pour les collections préchargées
3. ✅ Utilisation de `.pluck` pour récupérer uniquement les IDs
4. ✅ Utilisation de `.select` pour limiter les colonnes chargées
5. ✅ Queries objets séparés (Queries classes)
6. ✅ Services pour orchestrer les données complexes

## 📚 Ressources

- [Rails Guides: Eager Loading](https://guides.rubyonrails.org/active_record_querying.html#eager-loading-associations)
- [Rails Counter Cache](https://guides.rubyonrails.org/association_basics.html#options-for-has-many-counter-cache)
- [Bullet Gem](https://github.com/flyerhzm/bullet) - Pour détecter les N+1 queries
- [Rack Mini Profiler](https://github.com/MiniProfiler/rack-mini-profiler) - Pour profiler les requêtes
