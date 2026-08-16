# Liens Publics et Copie de Liens - Guide de Mise en Œuvre

## Vue d'ensemble

Cette fonctionnalité permet aux utilisateurs d'ActiveAdmin de copier facilement les liens publics (shareable links) de plusieurs ressources:
- **Produits** (`Item`)
- **Catégories** (`ProductCategory`)
- **Sous-catégories** (`ProductSubCategory`)
- **Boutiques** (`Shop`)

## Architecture Technique

### 1. Concern PublicLink

**Fichier**: `app/models/concerns/public_link.rb`

Un concern Rails réutilisable qui fournit:
- Méthode `public_url` (à implémenter dans chaque modèle)
- Alias `shareable_link` pour `public_url`

```ruby
# Inclusion dans les modèles
class Item < ApplicationRecord
  include PublicLink
  
  def public_url
    # Implémentation spécifique au modèle
  end
end
```

### 2. Implémentations Spécifiques par Modèle

#### Item (Produit)
- **URL publique**: `/fr/produits/:slug`
- **Généré via**: `Rails.application.routes.url_helpers.client_produit_url(id: friendly_id, host: app_host)`

```ruby
def public_url
  Rails.application.routes.url_helpers.client_produit_url(
    id: friendly_id,
    host: Rails.configuration.action_controller.asset_host || Rails.application.config.app_host || "localhost:3000"
  )
rescue
  nil
end
```

#### ProductCategory (Catégorie)
- **URL publique**: `/fr/categories/:slug`
- **Généré via**: `Rails.application.routes.url_helpers.client_category_url(slug: friendly_id, host: app_host)`

```ruby
def public_url
  Rails.application.routes.url_helpers.client_category_url(
    slug: friendly_id,
    host: Rails.configuration.action_controller.asset_host || Rails.application.config.app_host || "localhost:3000"
  )
rescue
  nil
end
```

#### ProductSubCategory (Sous-catégorie)
- **URL publique**: `/fr/categories/:category_slug/:subcategory_slug`
- **Dépendance**: Nécessite la catégorie parente

```ruby
def public_url
  Rails.application.routes.url_helpers.client_sub_category_url(
    category_slug: product_category.friendly_id,
    slug: friendly_id,
    host: Rails.configuration.action_controller.asset_host || Rails.application.config.app_host || "localhost:3000"
  )
rescue
  nil
end
```

#### Shop (Boutique)
- **URL publique**: `/fr/boutiques/:slug`
- **Généré via**: `Rails.application.routes.url_helpers.client_shop_url(slug: friendly_id, host: app_host)`

```ruby
def public_url
  Rails.application.routes.url_helpers.client_shop_url(
    slug: friendly_id,
    host: Rails.configuration.action_controller.asset_host || Rails.application.config.app_host || "localhost:3000"
  )
rescue
  nil
end
```

### 3. Stimulus Controller

**Fichier**: `app/javascript/controllers/copy_link_controller.js`

Gère la copie du lien dans le presse-papiers:
- Copie le texte via `navigator.clipboard.writeText()`
- Affiche un feedback visuel (changement de couleur du bouton)
- Gère les cas d'erreur

```javascript
export default class extends Controller {
  static targets = ["input", "button"]

  copy() {
    const link = this.inputTarget.value
    
    navigator.clipboard.writeText(link).then(() => {
      // Afficher "✓ Copié!" avec couleur verte
      const originalText = this.buttonTarget.textContent
      this.buttonTarget.textContent = "✓ Copié!"
      this.buttonTarget.classList.add("bg-green-600")
      this.buttonTarget.classList.remove("bg-blue-600")
      
      // Revenir à l'état initial après 2 secondes
      setTimeout(() => {
        this.buttonTarget.textContent = originalText
        this.buttonTarget.classList.remove("bg-green-600")
        this.buttonTarget.classList.add("bg-blue-600")
      }, 2000)
    }).catch(() => {
      // Gérer les erreurs
      this.buttonTarget.textContent = "✗ Erreur"
      this.buttonTarget.classList.add("bg-red-600")
      this.buttonTarget.classList.remove("bg-blue-600")
      
      setTimeout(() => {
        this.buttonTarget.textContent = "Copier"
        this.buttonTarget.classList.remove("bg-red-600")
        this.buttonTarget.classList.add("bg-blue-600")
      }, 2000)
    })
  }
}
```

### 4. Interface ActiveAdmin

#### Panel Affichage du Lien

Un panel nommé "🔗 Lien Public" est ajouté à la page `show` de chaque ressource:

```ruby
panel "🔗 Lien Public du [Ressource]" do
  div data: { controller: "copy-link" } do
    div style: "display: flex; gap: 10px; margin-bottom: 15px;" do
      input type: "text", 
            style: "flex: 1; padding: 8px 12px; ...",
            value: resource.public_url,
            readonly: true,
            data: { "copy-link-target": "input" }
      
      button type: "button",
              style: "padding: 8px 16px; background: #2563eb; ...",
              data: { "copy-link-target": "button", action: "copy-link#copy" } do
        "Copier"
      end
      
      a href: resource.public_url,
        target: "_blank",
        rel: "noopener noreferrer",
        style: "padding: 8px 16px; background: #e5e7eb; ...",
        title: "Ouvrir dans un nouvel onglet" do
        "Ouvrir ↗"
      end
    end
  end
end
```

**Composants**:
1. **Input en lecture seule**: Affiche l'URL complète
2. **Bouton Copier**: Copie le lien dans le presse-papiers
3. **Lien Ouvrir**: Ouvre l'URL dans un nouvel onglet

#### Intégration dans les Ressources

##### Items
- **Fichier**: `app/admin/items.rb`
- **Position**: Avant le panel "📊 Analytics du Produit"

##### ProductCategories
- **Fichier**: `app/admin/product_categories.rb`
- **Position**: Après la table d'attributs dans le panel show

##### ProductSubCategories
- **Fichier**: `app/admin/product_sub_categories.rb`
- **Position**: Après la table d'attributs dans le panel show

##### Shops
- **Fichier**: `app/admin/shops.rb`
- **Position**: Avant le panel "📊 Analytics de la Boutique"

## Usage

### Pour un Administrateur

1. **Accéder à la ressource**: Ouvrir un produit, catégorie, sous-catégorie ou boutique dans ActiveAdmin
2. **Localiser le panel**: Trouver le panel "🔗 Lien Public"
3. **Copier le lien**: 
   - Cliquer sur "Copier" → le lien est copié dans le presse-papiers
   - Le bouton vire au vert et affiche "✓ Copié!" pendant 2 secondes
4. **Ouvrir le lien**: 
   - Cliquer sur "Ouvrir ↗" pour vérifier le lien publiquement
   - S'ouvre dans un nouvel onglet

### Pour un Programmeur

```ruby
# Obtenir l'URL publique d'une ressource
product = Item.find(1)
url = product.public_url
# => "http://localhost:3000/fr/produits/mon-produit"

category = ProductCategory.find(1)
url = category.shareable_link  # Alias pour public_url
# => "http://localhost:3000/fr/categories/ma-categorie"

shop = Shop.find(1)
url = shop.public_url
# => "http://localhost:3000/fr/boutiques/ma-boutique"
```

## Configuration d'Environnement

### Host Configuration

L'URL publique utilise le host défini par:
1. `Rails.configuration.action_controller.asset_host` (priorité haute)
2. `Rails.application.config.app_host` (valeur de configuration)
3. Par défaut: `"localhost:3000"`

**Exemple de configuration** (`config/environments/production.rb`):
```ruby
config.action_controller.asset_host = ENV['APP_HOST'] || 'https://aa.com'
config.app_host = ENV['APP_HOST'] || 'https://aa.com'
```

## Gestion des Erreurs

### Cas de Erreurs Gérés

1. **Route non trouvée**:
   - `public_url` retourne `nil`
   - Le champ input affiche vide dans le panel

2. **Copie échouée** (navigateur ne supporte pas Clipboard API):
   - Le bouton affiche "✗ Erreur"
   - L'utilisateur peut toujours copier manuellement depuis l'input

3. **URL invalide**:
   - Retourne `nil` silencieusement
   - Utile pour ne pas casser l'interface admin

## Dépendances

### Gems
- `rails` 8.0+
- `activeadmin` 4.0.0.beta19+

### JavaScript
- Stimulus (via Hotwire)
- Navigator Clipboard API (supporté dans tous les navigateurs modernes)

### CSS
- Tailwind CSS (classes utilisées: `bg-blue-600`, `bg-green-600`, `bg-red-600`, etc.)

## Tailwind CSS

Les classes Tailwind utilisées dans le controller:
- `bg-blue-600`, `bg-green-600`, `bg-red-600`: Couleurs de fond
- Transitions: Gérées via CSS inline pour simplicité

Si vous utilisez Tailwind CSS, assurez-vous que le JIT compiler inclut les classes de couleur.

## Amélioration Futures

### Possibilités d'Améliorations
1. **URL courtes**: Implémenter des URLs courtes (bitly, custom shortener)
2. **QR Code**: Générer des QR codes pour chaque ressource
3. **Codes de partage**: Ajouter des codes de partage sociaux (Facebook, Twitter, WhatsApp)
4. **Analytics**: Tracker les clics sur les liens partagés
5. **Expiration**: Ajouter des URLs avec expiration temporaire
6. **Permissions**: Implémenter des URLs privées ou protéger par mot de passe

## Troubleshooting

### Le lien n'apparaît pas
- **Vérifier**: `resource.public_url` retourne nil
- **Solution**: Vérifier que la route existe dans `config/routes.rb`
- **Solution**: Vérifier que FriendlyId est configuré correctement

### Le bouton Copier ne fonctionne pas
- **Vérifier**: La console JavaScript pour les erreurs
- **Vérifier**: Le navigateur supporte la Clipboard API
- **Solution**: Mettre à jour le navigateur

### Le Stimulus controller ne se charge pas
- **Vérifier**: `data: { controller: "copy-link" }` est présent
- **Vérifier**: Le fichier existe: `app/javascript/controllers/copy_link_controller.js`
- **Solution**: Relancer le serveur Rails et Tailwind watcher

## Fichiers Modifiés

### Modèles
- `app/models/concerns/public_link.rb` (créé)
- `app/models/item.rb` (modifié - ajout de `include PublicLink` et `public_url`)
- `app/models/product_category.rb` (modifié - ajout de `include PublicLink` et `public_url`)
- `app/models/product_sub_category.rb` (modifié - ajout de `include PublicLink` et `public_url`)
- `app/models/shop.rb` (modifié - ajout de `include PublicLink` et `public_url`)

### Controllers
- `app/admin/items.rb` (modifié - ajout du panel public link)
- `app/admin/product_categories.rb` (modifié - ajout du panel public link)
- `app/admin/product_sub_categories.rb` (modifié - ajout du panel public link)
- `app/admin/shops.rb` (modifié - ajout du panel public link)

### JavaScript
- `app/javascript/controllers/copy_link_controller.js` (créé)

### Vues
- `app/views/shared/_public_link.html.erb` (créé - partielle réutilisable)

## Versioning

- **Version**: 1.0.0
- **Date**: 2024
- **Auteur**: aa Development Team
