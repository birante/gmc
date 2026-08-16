# Analyse de Performance - Page d'Accueil
**Date**: 12 février 2026  
**URL**: http://localhost:3000/fr

## Métriques Actuelles

| Métrique | Valeur | Statut |
|----------|--------|--------|
| Temps de réponse total | 526ms | 🟡 Acceptable |
| Temps réseau total | 660ms | 🟡 Acceptable |
| Requêtes SQL | **168** | 🔴 Très élevé |
| Temps SQL | 88.2ms | 🟢 Bon |
| Temps de rendu | 138.8ms | 🟢 Bon |
| Taille de la page | 581 KB | 🟢 Bon |
| Requêtes en cache | 35 | 🟢 Bon |

## Problèmes Identifiés

### 1. N+1 Query - ItemVariants (CRITIQUE)
**Localisation**: `app/models/shop_spotlight.rb:34` et `app/models/item.rb:116`

**Symptôme**: 
```ruby
ItemVariant Load (0.3ms) SELECT "item_variants".* FROM "item_variants" 
WHERE "item_variants"."item_id" = 143 AND "item_variants"."is_default" = TRUE
# Répété 6 fois pour chaque produit
```

**Solution**:
```ruby
# Dans shop_spotlight.rb ou le service qui charge les items
items = Item.where(id: item_ids)
           .includes(:variants, :currency, :shop, main_image_attachment: :blob)
           .order(position: :asc)
```

**Gain estimé**: -6 à -20 requêtes SQL, ~10-30ms

---

### 2. N+1 Query - ActiveStorage Blobs pour Catégories (ÉLEVÉ)
**Localisation**: `app/helpers/application_helper.rb:11`

**Symptôme**:
```ruby
ActiveStorage::Blob Load (0.2ms) SELECT "active_storage_blobs".* 
FROM "active_storage_blobs" WHERE "active_storage_blobs"."id" = 2
# Répété 12 fois pour chaque icône de catégorie
```

**Solution**:
```ruby
# Dans application_helper.rb
def active_categories_with_subcategories
  Rails.cache.fetch("categories/with_subcategories/v1", expires_in: 1.hour) do
    ProductCategory.where(is_active: true)
      .includes(
        sub_categories: [icon_attachment: :blob]
      )
      .order(:position, :name)
      .to_a
  end
end
```

**Gain estimé**: -12 requêtes SQL, ~5-10ms

---

### 3. Création Redondante de Panier Invité
**Localisation**: `app/controllers/application_controller.rb:86`

**Symptôme**:
```ruby
Cart Create (0.9ms) INSERT INTO "carts" 
# Créé même si l'utilisateur ne va pas acheter
```

**Solution**: Création lazy (seulement quand nécessaire - ajout au panier)

**Gain estimé**: -4 requêtes SQL, ~5ms pour utilisateurs non-acheteurs

---

### 4. Chargement Séquentiel des Blobs dans Shop Spotlight
**Localisation**: `app/views/shared/storefront/_shop_spotlight.html.erb`

**Symptôme**: Chargement individuel des images produits

**Solution**:
```ruby
# Dans le modèle ShopSpotlight
def items
  @items ||= Item.where(id: item_ids)
                 .includes(
                   :currency,
                   :shop,
                   variants: [],
                   main_image_attachment: :blob
                 )
                 .sort_by { |item| item_ids.index(item.id) }
end
```

**Gain estimé**: -6 requêtes SQL, ~3-5ms

---

### 5. Requêtes SQL Complexes dans le Footer/Header
**Localisation**: `shared/_categories_mega_menu.html.erb`

**Symptôme**: Jointures complexes à chaque requête

**Solution**: Mise en cache complète du mega menu
```ruby
# Dans application_helper.rb
def cached_mega_menu
  Rails.cache.fetch("mega_menu/v2/#{I18n.locale}", expires_in: 30.minutes) do
    render partial: 'shared/categories_mega_menu'
  end
end
```

**Gain estimé**: -15 requêtes SQL, ~8-12ms

---

## Plan d'Optimisation Priorisé

### Phase 1 - Quick Wins (Gain: ~50-80 requêtes, 30-60ms)
1. ✅ Ajouter `includes(:variants)` dans ShopSpotlight
2. ✅ Cacher le mega menu des catégories
3. ✅ Lazy loading du panier invité

### Phase 2 - Optimisations Medium (Gain: ~20-40 requêtes, 15-30ms)
4. ✅ Prefetch des ActiveStorage blobs dans les helpers
5. ✅ Optimiser les requêtes du promo carousel
6. ✅ Réduire les charges de currency/shop (déjà en cache)

### Phase 3 - Caching Avancé (Gain: 100ms+ sur pages suivantes)
7. ⏳ Fragment caching pour sections statiques
8. ⏳ Russian Doll caching pour les produits
9. ⏳ HTTP caching headers pour assets

### Phase 4 - Infrastructure (Gain variable)
10. ⏳ CDN pour images ActiveStorage
11. ⏳ Database read replicas pour queries lourdes
12. ⏳ Redis cache backend au lieu de Solid Cache

---

## Métriques Cibles Post-Optimisation

| Métrique | Actuel | Cible | Objectif |
|----------|--------|-------|----------|
| Temps total | 526ms | **< 300ms** | -40% |
| Requêtes SQL | 168 | **< 50** | -70% |
| Temps SQL | 88ms | **< 40ms** | -55% |
| Taille page | 581 KB | **< 500 KB** | -15% |

---

## Code à Optimiser

### Fichier Prioritaire 1: `app/models/shop_spotlight.rb`

**Avant** (ligne 34):
```ruby
def items
  @items ||= Item.where(id: item_ids)
                 .order(Arel.sql("array_position(ARRAY[#{item_ids.join(',')}]::bigint[], items.id)"))
end
```

**Après**:
```ruby
def items
  return @items if defined?(@items)
  
  @items = Item.where(id: item_ids)
               .includes(
                 :currency,
                 :shop,
                 variants: [],
                 main_image_attachment: :blob
               )
               .to_a
               .sort_by { |item| item_ids.index(item.id) }
end
```

---

### Fichier Prioritaire 2: `app/helpers/application_helper.rb`

**Avant**:
```ruby
def active_categories_with_subcategories
  ProductCategory.where(is_active: true)
    .includes(sub_categories: [:icon_attachment])
    .order(:position, :name)
end
```

**Après**:
```ruby
def active_categories_with_subcategories
  Rails.cache.fetch("categories/active/v2/#{I18n.locale}", expires_in: 1.hour) do
    ProductCategory.where(is_active: true)
      .includes(
        sub_categories: [icon_attachment: :blob]
      )
      .order(:position, :name)
      .to_a
  end
end
```

---

### Fichier Prioritaire 3: `app/controllers/application_controller.rb`

**Avant** (ligne 86):
```ruby
def find_or_create_guest_cart
  # Crée toujours un panier
  cart = Cart.create!(status: 'active', slug: "guest-#{SecureRandom.uuid}")
  session[:cart_id] = cart.id
  cart
end
```

**Après**:
```ruby
def find_or_create_guest_cart
  return @guest_cart if defined?(@guest_cart)
  
  cart_id = session[:cart_id]
  @guest_cart = if cart_id.present?
    Cart.find_by(id: cart_id, user_id: nil, status: 'active')
  end
  
  # Création lazy seulement si déjà un cart_id en session
  @guest_cart ||= nil # Ne créer qu'au moment de l'ajout au panier
end
```

---

## Tests de Régression

Après optimisations, vérifier :
- [ ] Produits s'affichent correctement dans Shop Spotlight
- [ ] Mega menu catégories fonctionne
- [ ] Images des produits chargent
- [ ] Ajout au panier fonctionne
- [ ] Aucune erreur N+1 query dans les logs

---

## Monitoring

```bash
# Relancer l'analyse
curl -o /dev/null -s -w "Total: %{time_total}s\n" http://localhost:3000/fr

# Compter les requêtes SQL
tail -100 log/development.log | grep "SELECT\|INSERT\|UPDATE" | wc -l

# Identifier les requêtes lentes
tail -500 log/development.log | grep "Load ([0-9]\+\.[0-9]\+ms)" | sort -rn
```

---

## Ressources

- [Rails Performance Guide](https://guides.rubyonrails.org/performance_testing.html)
- [Bullet Gem](https://github.com/flyerhzm/bullet) - Détecte N+1 queries
- [Rack Mini Profiler](https://github.com/MiniProfiler/rack-mini-profiler) - Analyse détaillée

