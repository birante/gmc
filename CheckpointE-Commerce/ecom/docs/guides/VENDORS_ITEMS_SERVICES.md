# 🔧 Services pour Vendors::ItemsController

## Vue d'ensemble

Le contrôleur `Vendors::ItemsController` a été refactorisé pour utiliser des services et réduire la complexité. La logique métier a été extraite dans des services dédiés.

## 📦 Services créés

### 1. `Vendors::ItemCreationService`

**Responsabilité** : Gérer la création complète d'un produit avec toutes ses variantes.

**Localisation** : `app/services/vendors/item_creation_service.rb`

**Utilisation** :
```ruby
service = Vendors::ItemCreationService.new(
  shop: @current_shop,
  params: item_params,
  commit: params[:commit]
)
result = service.call

if result.success?
  # Gérer le succès
else
  # Gérer les erreurs
end
```

**Fonctionnalités** :
- ✅ Préparation des attributs (mapping des champs legacy)
- ✅ Extraction des variantes avec `combination_data`
- ✅ Normalisation des variantes normales
- ✅ Création des variantes avec attributs via `VariantCreationService`
- ✅ Gestion de l'option "publish" (activation du produit)

### 2. `Vendors::ItemUpdateService`

**Responsabilité** : Gérer la mise à jour d'un produit avec gestion du statut de validation.

**Localisation** : `app/services/vendors/item_update_service.rb`

**Utilisation** :
```ruby
service = Vendors::ItemUpdateService.new(
  item: @item,
  params: item_params
)
result = service.call

if result.success?
  if result.status_changed
    # Produit repassé en pending
  else
    # Mise à jour normale
  end
end
```

**Fonctionnalités** :
- ✅ Mise à jour des attributs (sans modifier `validation_status`)
- ✅ Détection si le produit était approuvé
- ✅ Repassage automatique en `pending` si le produit était approuvé
- ✅ Retourne un `Result` avec `status_changed` pour savoir si le statut a changé

### 3. `Vendors::ItemFormDataService`

**Responsabilité** : Charger toutes les données nécessaires pour les formulaires (new/edit).

**Localisation** : `app/services/vendors/item_form_data_service.rb`

**Utilisation** :
```ruby
form_data = Vendors::ItemFormDataService.new(
  vendor: @vendor,
  shop: @current_shop
).call

@product_categories = form_data[:product_categories]
@currencies = form_data[:currencies]
@delivery_categories = form_data[:delivery_categories]
@categories_json = form_data[:categories_json]
```

**Fonctionnalités** :
- ✅ Charge les catégories de produits actives
- ✅ Charge les devises actives
- ✅ Charge les catégories de livraison
- ✅ Charge les attributs de produits
- ✅ Génère le JSON des catégories pour JavaScript

### 4. `Vendors::ItemSearchService`

**Responsabilité** : Gérer la recherche, le filtrage et la pagination des produits.

**Localisation** : `app/services/vendors/item_search_service.rb`

**Utilisation** :
```ruby
@items = Vendors::ItemSearchService.new(
  vendor: @vendor,
  shop_condition: @shop_condition,
  shop_value: @shop_value,
  params: params
).call
```

**Fonctionnalités** :
- ✅ Recherche par nom ou description
- ✅ Filtre par statut de validation
- ✅ Filtre par statut actif/inactif
- ✅ Pagination (si Kaminari disponible)
- ✅ Inclusions optimisées (includes)

## 📊 Avant / Après

### Avant (271 lignes)
- ❌ Logique métier mélangée avec la logique de contrôleur
- ❌ Code dupliqué (chargement des données de formulaire)
- ❌ Actions très longues (create: ~90 lignes)
- ❌ Difficile à tester

### Après (189 lignes)
- ✅ Contrôleur allégé et focalisé sur la coordination
- ✅ Logique métier dans des services testables
- ✅ Code réutilisable
- ✅ Actions courtes et claires
- ✅ Facile à tester et maintenir

## 🎯 Structure du contrôleur refactorisé

```ruby
module Vendors
  class ItemsController < BaseController
    def index
      # Utilise ItemSearchService et ItemFormDataService
    end

    def new
      # Utilise ItemFormDataService
    end

    def create
      # Utilise ItemCreationService
      # Méthodes helper: handle_successful_creation, handle_failed_creation
    end

    def edit
      # Utilise ItemFormDataService
    end

    def update
      # Utilise ItemUpdateService
      # Méthodes helper: handle_successful_update, handle_failed_update
    end

    private
      # Méthodes helper pour gérer les réponses
      # item_params pour les strong parameters
  end
end
```

## ✅ Avantages

1. **Séparation des responsabilités** : Chaque service a une responsabilité claire
2. **Testabilité** : Les services peuvent être testés indépendamment
3. **Réutilisabilité** : Les services peuvent être utilisés ailleurs
4. **Maintenabilité** : Code plus facile à comprendre et modifier
5. **Lisibilité** : Contrôleur beaucoup plus court et clair

## 🔄 Flux de données

### Création
```
Controller → ItemCreationService → VariantCreationService → Item
```

### Mise à jour
```
Controller → ItemUpdateService → Item
```

### Affichage formulaire
```
Controller → ItemFormDataService → Données formatées
```

### Recherche
```
Controller → ItemSearchService → Items filtrés
```

## 📝 Notes

- Tous les services retournent un objet `Result` avec `success?`, `item`, `errors`
- Les services loggent leurs actions pour le debugging
- Les services gèrent les erreurs proprement
- Le contrôleur reste responsable de la coordination et des réponses HTTP

---

## 📘 Comprendre Produit vs Variante (Cas d'usage vendeur)

Si vous vous sentez perdu, retenez cette règle simple:

- **Produit (`Item`)** = la fiche commerciale (nom, description, images, catégorie, devise, promo globale).
- **Variante (`ItemVariant`)** = ce qui est réellement vendu (SKU, prix final, stock, attributs comme taille/couleur).

En pratique, le client ajoute au panier une **variante**, jamais le produit "abstrait".

### Ce qui se passe lors de la création d'un produit

1. Le vendeur crée une fiche produit.
2. Le système doit garantir qu'il existe au moins une variante.
3. Si aucune variante détaillée n'est fournie, une **variante par défaut** est créée.

Conclusion: un produit sans variante exploitable ne doit pas rester vendable.

---

## 🧭 Parcours vendeur: pages utilisées pour les variantes

### 1) Liste des produits

- **URL**: `/fr/vendors/items?shop_slug=<slug>`
- **Action**: `Vendors::ItemsController#index`
- **Vue**: `app/views/vendors/items/index.html.erb`
- **Rôle**: choisir le produit à consulter.

### 2) Détail produit (lecture)

- **URL**: `/fr/vendors/items/:id?shop_slug=<slug>`
- **Action**: `Vendors::ItemsController#show`
- **Vue**: `app/views/vendors/items/show.html.erb`
- **Rôle**: consulter la fiche, puis naviguer vers édition/variantes.

### 3) Éditer le produit (attributs de base)

- **URL**: `/fr/vendors/items/:id/edit?shop_slug=<slug>`
- **Action**: `Vendors::ItemsController#edit` puis `#update`
- **Vue**: `app/views/vendors/items/edit.html.erb`
- **Rôle**: modifier les infos globales du produit (pas la granularité fine de chaque variante).

### 4) Liste et gestion des variantes

- **URL**: `/fr/vendors/items/:item_id/variants?shop_slug=<slug>`
- **Action**: `Vendors::ItemVariantsController#index`
- **Vue**: `app/views/vendors/item_variants/index.html.erb`
- **Rôle**: voir toutes les variantes, prix, stock, et accéder à création/édition.

### 5) Créer une variante

- **URL**: `/fr/vendors/items/:item_id/variants/new?shop_slug=<slug>`
- **Action**: `Vendors::ItemVariantsController#new` puis `#create`
- **Vue**: `app/views/vendors/item_variants/new.html.erb`
- **Rôle**: ajouter une combinaison (ex: Taille M + Couleur Bleu) avec son prix et stock.

### 6) Éditer une variante

- **URL**: `/fr/vendors/items/:item_id/variants/:id/edit?shop_slug=<slug>`
- **Action**: `Vendors::ItemVariantsController#edit` puis `#update`
- **Vue**: `app/views/vendors/item_variants/edit.html.erb`
- **Rôle**: corriger prix, stock, SKU, promo d'une variante précise.

### 7) Générer les variantes depuis les attributs

- **URL (POST)**: `/fr/vendors/items/:id/generate_variants?shop_slug=<slug>`
- **Action**: `Vendors::ItemsController#generate_variants`
- **Rôle**: créer automatiquement les combinaisons possibles à partir des attributs du produit.

---

## 🧪 Exemples concrets

### Exemple A: produit simple (une seule variante)

Cas: "Chargeur USB-C" sans taille/couleur.

1. Le vendeur crée le produit.
2. Le système garde/produit une variante par défaut:
  - SKU: `1-DEFAULT`
  - Prix: `5 000`
  - Stock: `20`
3. Le client voit un seul choix achetable.

### Exemple B: produit à combinaisons (plusieurs variantes)

Cas: "T-shirt aa" avec attributs:

- Taille: S, M, L
- Couleur: Noir, Blanc

Combinaisons possibles: \(3 \times 2 = 6\) variantes.

Flux recommandé:

1. Éditer le produit pour définir les attributs.
2. Lancer "générer les variantes".
3. Aller sur la liste des variantes pour ajuster prix/stock SKU ligne par ligne.

Exemple de lignes obtenues:

- T-shirt | Taille S | Noir | 8 000 FCFA | Stock 5
- T-shirt | Taille M | Noir | 8 500 FCFA | Stock 3
- T-shirt | Taille L | Blanc | 9 000 FCFA | Stock 2

### Exemple C: promo ciblée sur une variante

Cas: seule la variante "Taille L - Blanc" est en promo.

1. Ouvrir la page d'édition de cette variante.
2. Mettre `sale_price` sur cette variante uniquement.
3. Les autres variantes gardent leur prix normal.

---

## ✅ Règles de décision rapide

- Changer nom/description/images/catégorie du produit: **page produit (edit)**.
- Changer prix/stock/SKU d'une combinaison précise: **page variante (edit)**.
- Ajouter une nouvelle combinaison: **variante new**.
- Créer en masse toutes les combinaisons: **generate_variants**.

Cette séparation évite de mélanger le niveau "marketing" (produit) et le niveau "vente opérationnelle" (variante).
