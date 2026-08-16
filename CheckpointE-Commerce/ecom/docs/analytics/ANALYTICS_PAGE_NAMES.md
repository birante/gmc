# Amélioration des Noms de Pages dans Analytics

## ✅ Problèmes résolus

1. Les noms de pages dans l'admin analytics (`/admin/analytics`) n'étaient pas toujours affichés correctement ou étaient illisibles
2. Pas de support multilingue (FR/EN)
3. Pas de pagination pour les pages (limité à 20)

## 🔧 Corrections apportées

### 1. **Correction du bug d'affichage** (app/admin/analytics.rb)
- ❌ Avant : `page[0]` causait une erreur
- ✅ Après : `page` directement avec gestion des valeurs nulles

### 2. **Ajout de mappings de pages** (app/services/analytics/event_definitions.rb)

Nouveaux mappings ajoutés pour les pages Vendors et Employees :

#### Pages Vendeur
- `vendors/dashboard#index` → "📊 Tableau de bord vendeur"
- `vendors/items#index` → "🏷️ Produits vendeur"
- `vendors/items#new` → "➕ Nouveau produit vendeur"
- `vendors/items#edit` → "✏️ Édition produit vendeur"
- `vendors/orders#index` → "📦 Commandes vendeur"
- `vendors/orders#show` → "📦 Détail commande vendeur"
- `vendors/settings#index` → "⚙️ Paramètres vendeur"
- `vendors/shops#edit` → "🏪 Édition boutique"
- `vendors/analytics#index` → "📊 Analytics vendeur"

#### Pages Employé
- `employees/dashboard#index` → "📊 Tableau de bord employé"
- `employees/items#index` → "🏷️ Produits employé"
- `employees/items#new` → "➕ Nouveau produit employé"
- `employees/items#edit` → "✏️ Édition produit employé"
- `employees/orders#index` → "📦 Commandes employé"
- `employees/orders#show` → "📦 Détail commande employé"
- `employees/analytics#index` → "📊 Analytics employé"

### 3. **Traductions I18n (FR/EN)**

Nouveaux fichiers de traduction :
- ✅ `config/locales/analytics.fr.yml` - Traductions françaises
- ✅ `config/locales/analytics.en.yml` - Traductions anglaises
- ✅ Tous les noms de pages traduits avec émojis
- ✅ Support automatique de la locale courante

### 4. **Méthode de rendu lisible** (humanize_page_name)

Nouvelle méthode `Analytics::EventDefinitions.humanize_page_name(page_name, locale: I18n.locale)` qui :
- ✅ Utilise I18n pour les traductions
- ✅ Convertit les noms techniques en noms lisibles avec émojis
- ✅ Gère les valeurs nulles/vides ("Page sans nom" / "Unnamed Page")
- ✅ Utilise `titleize` pour les pages non traduites (fallback)
- ✅ Supporte FR et EN automatiquement

### 5. **Pagination ajoutée**

Le tableau "Pages les Plus Visitées" est maintenant paginé :
- ✅ **20 pages par page** au lieu d'une limite fixe de 20
- ✅ Navigation : Premier | Précédent | [1] [2] [3] ... | Suivant | Dernier
- ✅ Affichage : "Affichage de 1 à 20 sur 145 pages"
- ✅ Paramètres de dates préservés lors de la pagination

### 6. **Affichage amélioré dans l'admin**

Le tableau "Pages les Plus Visitées" affiche maintenant :
- **Ligne 1** : Nom lisible avec émoji (ex: "📊 Tableau de bord vendeur")
- **Ligne 2** : Nom technique en petit (ex: "vendor_dashboard") si différent
- **Police monospace** pour le nom technique (plus facile à lire)
- **Pagination** pour voir toutes les pages au-delà de 20

## 📊 Exemple d'affichage

### Avant
```
Page                    Vues    % du Total
vendor_dashboard         245     15.2%
vendors_items_index      189     11.7%
N/A                       45      2.8%
```

### Après
```
Page                                Vues    % du Total
📊 Tableau de bord vendeur          245     15.2%
   vendor_dashboard
🏷️ Produits vendeur                189     11.7%
   vendors_items_index
Page sans nom                        45      2.8%
```

## 🔄 Fallback pour pages non mappées

Pour les pages sans mapping explicite, le système :
1. Génère un nom automatique : `"#{controller}_#{action}".parameterize(separator: "_")`
2. Le rend lisible avec `titleize` (ex: "Vendors Items Index")
3. Affiche le nom technique en dessous

## 🌐 Support multilingue

Les noms de pages sont maintenant traduits automatiquement selon la locale :

### Français (fr)
- "vendor_dashboard" → "📊 Tableau de bord vendeur"
- "employee_products" → "🏷️ Produits"

### Anglais (en)
- "vendor_dashboard" → "📊 Vendor Dashboard"
- "employee_products" → "🏷️ Products"

### Changement de langue

La langue s'adapte automatiquement à `I18n.locale`. Pour forcer une langue :

```ruby
Analytics::EventDefinitions.humanize_page_name("vendor_dashboard", locale: :en)
# => "📊 Vendor Dashboard"
```

## 📝 Ajouter de nouvelles pages

Pour ajouter un mapping pour une nouvelle page :

### Étape 1 : Définir la constante (Pages module)

```ruby
module Pages
  MY_NEW_PAGE = "my_new_page"
end
```

### Étape 2 : Ajouter le mapping (page_name_for method)

```ruby
mapping = {
  # ...
  "my_controller#my_action" => Pages::MY_NEW_PAGE,
}
```

### Étape 3 : Ajouter les traductions (analytics.fr.yml et analytics.en.yml)

**analytics.fr.yml**
```yaml
fr:
  analytics:
    page_names:
      my_new_page: "🎨 Mon Nouveau Titre"
```

**analytics.en.yml**
```yaml
en:
  analytics:
    page_names:
      my_new_page: "🎨 My New Title"
```

## 🎯 Pages publiques déjà mappées

Toutes ces pages ont des noms lisibles :
- 🏠 Accueil
- 🏪 Liste/Détail boutiques
- 🏷️ Liste/Détail produits
- 🛒 Panier
- 💳 Paiement
- 👤 Profil utilisateur
- 📦 Commandes
- 🔑 Connexion/Inscription

## 🐛 Dépannage

### Les noms ne s'affichent toujours pas

Vérifier que :
1. Le concern `Trackable` est inclus dans le contrôleur
2. `track_page_view_automatically` est appelé
3. Le serveur a été redémarré après les modifications

### Pages affichées comme "Page sans nom" / "Unnamed Page"

Cela signifie que `page_name` n'est pas enregistré dans l'événement.

**Solution** : Ajouter le mapping dans `page_name_for` ou vérifier que le tracking fonctionne.

### Nom technique affiché mais pas de nom lisible

Ajouter les traductions dans les fichiers `analytics.fr.yml` et `analytics.en.yml` :

**analytics.fr.yml**
```yaml
fr:
  analytics:
    page_names:
      ma_page: "🎯 Mon Titre Lisible"
```

**analytics.en.yml**
```yaml
en:
  analytics:
    page_names:
      ma_page: "🎯 My Readable Title"
```

### La pagination ne s'affiche pas

La pagination s'affiche uniquement s'il y a **plus de 20 pages** dans les résultats.

Pour tester, assurez-vous d'avoir suffisamment de données.

## 📈 Impact

- ✅ **Support multilingue** - FR et EN automatique
- ✅ **Meilleure lisibilité** des rapports analytics
- ✅ **Plus facile d'identifier** les pages populaires
- ✅ **Noms cohérents** avec émojis pour une navigation visuelle rapide
- ✅ **Fallback automatique** pour les nouvelles pages
- ✅ **Pagination** pour gérer un grand nombre de pages
- ✅ **Maintenabilité** - Traductions dans des fichiers séparés

## 🔗 Fichiers créés/modifiés

### Créés
1. `config/locales/analytics.fr.yml` - Traductions françaises
2. `config/locales/analytics.en.yml` - Traductions anglaises

### Modifiés
1. `app/admin/analytics.rb` - Affichage des noms de pages + pagination
2. `app/services/analytics/event_definitions.rb` - Utilisation I18n

## 📊 Exemple de pagination

Quand il y a plus de 20 pages visitées :

```
Pages les Plus Visitées

[Tableau avec 20 lignes]

Affichage de 1 à 20 sur 145 pages

[← Précédent] [1] [2] [3] ... [8] [Suivant →]
```

