# 📦 Workflow Catégorie de Livraison

## Vue d'ensemble

Ce document décrit le workflow de gestion des catégories de livraison pour les produits.

## 🔄 Flux de validation

### 1. Création du produit (Vendor)

- ✅ Le vendor crée un produit avec `validation_status: "pending"`
- ✅ `delivery_category` peut être **null** à ce stade
- ✅ Le produit est créé en attente de validation

### 2. Modification du produit (Vendor)

- ✅ Le vendor peut modifier son produit
- ✅ **Si le produit était approuvé**, il repasse automatiquement en `"pending"` après modification
- ✅ Le vendor peut sélectionner une catégorie de livraison (optionnel)
- ✅ Message affiché : "Produit modifié avec succès. Il repasse en attente de validation par aa."

### 3. Validation par aa (Admin)

- ✅ aa peut voir tous les produits en attente dans l'admin
- ✅ **Pour approuver un produit**, aa **DOIT** sélectionner une catégorie de livraison :
  - Léger
  - Moyen
  - Grand
- ✅ Si aa essaie d'approuver sans catégorie, une erreur s'affiche
- ✅ Une fois approuvé avec une catégorie, le produit peut être mis en vente

## 📋 Validations

### Modèle Item

```ruby
# delivery_category est optionnel par défaut
belongs_to :delivery_category, optional: true

# Mais requis si le produit est approuvé
validates :delivery_category, presence: { message: "doit être sélectionnée" }, if: :approved?
```

**Comportement** :
- ✅ `delivery_category` peut être `null` pour les produits en `pending` ou `rejected`
- ❌ `delivery_category` est **requis** pour les produits `approved`

## 🎯 Interface Admin

### Formulaire d'édition/création

- ✅ Champ `delivery_category` disponible dans le formulaire admin
- ✅ Message d'aide : "Requis pour approuver le produit. Choisissez: Léger, Moyen ou Grand."
- ✅ Validation côté contrôleur : impossible d'approuver sans catégorie

### Affichage

- ✅ Colonne `delivery_category` dans la liste des produits
- ✅ Filtre par `delivery_category` disponible
- ✅ Affichage dans la page de détail

## 🛒 Interface Vendor

### Formulaire d'édition

- ✅ Champ `delivery_category` disponible (optionnel)
- ✅ Indication visuelle si le produit est approuvé (astérisque rouge)
- ✅ Message : "Requis pour les produits approuvés"

### Comportement lors de la modification

- ✅ Si le produit était `approved` → repasse en `pending` automatiquement
- ✅ Le vendor ne peut pas modifier le `validation_status` directement
- ✅ Notification claire que le produit doit être revalidé

## 🔍 États possibles

### Produit créé (pending)
```
validation_status: "pending"
delivery_category: null ✅ (autorisé)
```

### Produit modifié (pending)
```
validation_status: "pending" (repassé automatiquement)
delivery_category: null ou sélectionnée ✅ (autorisé)
```

### Produit approuvé
```
validation_status: "approved"
delivery_category: REQUIS ❌ (validation échoue si null)
```

## 📝 Exemples d'utilisation

### Création d'un produit (Vendor)
```ruby
# ✅ Valide - pas de delivery_category
item = Item.create!(
  name: "Produit Test",
  validation_status: "pending",
  delivery_category: nil  # OK
)
```

### Modification d'un produit approuvé (Vendor)
```ruby
# Avant modification
item.validation_status # => "approved"
item.delivery_category # => #<DeliveryCategory name: "Moyen">

# Après modification
item.update(name: "Nouveau nom")
item.validation_status # => "pending" (automatique)
item.delivery_category # => #<DeliveryCategory name: "Moyen"> (conservé)
```

### Approbation d'un produit (Admin)
```ruby
# ❌ Échoue - pas de delivery_category
item.update(validation_status: "approved", delivery_category: nil)
# => Error: "Catégorie de livraison doit être sélectionnée"

# ✅ Réussit - avec delivery_category
item.update(
  validation_status: "approved",
  delivery_category: DeliveryCategory.find_by(code: "medium")
)
```

## ✅ Checklist de validation

Pour qu'un produit soit approuvé, il doit avoir :

- [x] Au moins une variante
- [x] Un nom
- [x] **Une catégorie de livraison** (Léger, Moyen ou Grand)
- [x] Toutes les autres validations passent

## 🔄 Workflow complet

```
1. Vendor crée produit
   └─> validation_status: "pending"
   └─> delivery_category: null ✅

2. Vendor modifie produit (si approuvé)
   └─> validation_status: "pending" (automatique)
   └─> delivery_category: conservée ou null ✅

3. aa valide produit
   └─> Sélectionne delivery_category (Léger/Moyen/Grand)
   └─> validation_status: "approved"
   └─> delivery_category: REQUIS ✅
```

## 🎨 Interface utilisateur

### Admin (aa)
- Champ de sélection avec toutes les catégories disponibles
- Message d'aide clair
- Validation empêche l'approbation sans catégorie

### Vendor
- Champ de sélection optionnel
- Indication visuelle si requis (produit approuvé)
- Notification après modification que le produit repasse en validation
