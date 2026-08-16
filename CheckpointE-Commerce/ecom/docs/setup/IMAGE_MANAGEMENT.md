# Gestion des Images dans aa

## Images Disponibles

Les modèles suivants supportent les uploads d'images via ActiveAdmin:

### 1. **Bannières de la Page d'Accueil**
- **HeroSliderSlide** - Slides du héros (hero slider)
- **PromoBanner** - Bannières promotionnelles
- **OfficialBrandBanner** - Bannières de marques officielles
- **LocalShopBanner** - Bannières de boutiques locales
- **SecondaryBanner** - Bannières secondaires

### 2. **Produits & Catégories**
- **Item** - Produits (image principale + images multiples)
- **ProductCategory** - Catégories de produits (icône)
- **ProductSubCategory** - Sous-catégories (icône)

### 3. **Boutiques**
- **Shop** - Logo et image de bannière

## Configuration des Images

### ActiveAdmin Integration

Tous les fichiers admin sont configurés pour supporter les uploads d'images:

```ruby
# Exemple dans app/admin/hero_slider_slides.rb
permit_params :image  # Autoriser l'upload d'images

# Dans le formulaire
f.input :image, as: :file, hint: "Affichage de l'image actuelle"
```

### Models Configuration

Les modèles ont les attachements suivants:

```ruby
# Bannières (une image par bannière)
has_one_attached :image

# Produits (image principale + galerie)
has_one_attached :main_image
has_many_attached :images

# Catégories & Boutiques (icône/logo)
has_one_attached :icon    # Catégories
has_one_attached :logo    # Boutiques
has_one_attached :banner_image  # Bannière de boutique
```

## Utilisation en Production

Les images sont stockées dans le service de stockage configuré (par défaut: `local` en développement, `s3` en production).

### Configuration Requise

1. **Développement**: Les images sont stockées dans `storage/` (dossier local)
2. **Production**: Configurer AWS S3 dans `config/storage.yml`

### Accès aux Images

```erb
<!-- Dans les vues -->
<%= image_tag banner.image, alt: banner.title %>

<!-- Avec URL directe -->
<%= url_for(banner.image) %>

<!-- Avec variants (redimensionnement) -->
<%= image_tag banner.image.variant(resize_to_limit: [300, 300]) %>
```

## Ransack - Attributs Searchables

Tous les modèles avec images ont leur `ransackable_attributes` configuré pour la recherche:

```ruby
def self.ransackable_attributes(auth_object = nil)
  ["id", "title", "created_at", "updated_at", ...]  # Tous les attributs searchables
end
```

## Validations Recommandées

Pour ajouter des validations sur les images dans les modèles:

```ruby
class HeroSliderSlide < ApplicationRecord
  # Validations optionnelles
  validates :image, presence: true, on: :create
  
  # Valider le type de fichier
  validate :image_type_valid
  
  private
  
  def image_type_valid
    if image.present? && !image.content_type.in?(%w[image/jpeg image/png image/webp])
      errors.add(:image, 'must be JPEG, PNG, or WebP')
    end
  end
end
```

## Cleanup des Images

Pour supprimer les images orphelines (modèle supprimé):

```bash
rails active_storage:purge  # Supprimer les attachements supprimés
```

## Intégration avec le Frontend

Les images sont accessibles via les URLs des assets Rails:

```erb
<!-- Affichage simple -->
<img src="<%= url_for(banner.image) %>" alt="<%= banner.title %>">

<!-- Avec Turbo/Hotwire -->
<div data-banner-id="<%= banner.id %>">
  <%= image_tag banner.image %>
</div>
```
