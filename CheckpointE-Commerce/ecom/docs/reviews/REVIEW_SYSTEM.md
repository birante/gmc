# Système d'Avis Clients - Documentation

## Vue d'ensemble

Le système d'avis permet aux clients d'évaluer et de commenter les produits qu'ils ont achetés. Les avis sont modérés par les administrateurs avant publication.

## Modèle Review

### Attributs
- `user_id` : Client qui a laissé l'avis (User)
- `item_id` : Produit évalué (Item)
- `order_item_id` : Article de commande (optionnel, OrderItem)
- `rating` : Note de 1 à 5 étoiles (integer, requis)
- `comment` : Commentaire textuel (text, max 2000 caractères)
- `status` : Statut de modération (enum: pending, approved, rejected)
- `helpful_count` : Nombre d'utilisateurs ayant trouvé l'avis utile (integer, default: 0)
- `images` : Photos du produit (has_many_attached, max 5)

### Validations
- Un client ne peut laisser qu'un seul avis par produit (validation unique sur `user_id` + `item_id`)
- `rating` doit être entre 1 et 5
- `comment` limité à 2000 caractères

### Callbacks
- `after_create` : Met à jour la note moyenne du produit
- `after_update` : Met à jour la note moyenne si `rating` ou `status` change
- `after_destroy` : Met à jour la note moyenne du produit

## Modèle Item

### Nouvelle colonne
- `average_rating` : Note moyenne calculée automatiquement (decimal, precision: 3, scale: 2)

### Associations
- `has_many :reviews, dependent: :destroy`

### Méthodes calculées
- La note moyenne est calculée automatiquement à partir des avis approuvés uniquement
- Mise à jour automatique lors de la création/modification/suppression d'un avis

## Routes

```ruby
namespace :client do
  resources :reviews, only: [:index, :create, :update, :destroy] do
    member do
      post :mark_as_helpful
    end
    collection do
      get :my_reviews
    end
  end
end
```

## Contrôleur Client::ReviewsController

### Actions
- `index` : Liste des avis (filtrés par item si `item_id` présent)
- `my_reviews` : Liste des avis de l'utilisateur connecté
- `create` : Créer un nouvel avis (status: "pending" par défaut)
- `update` : Modifier un avis (seulement si créé il y a moins de 7 jours)
- `destroy` : Supprimer son propre avis
- `mark_as_helpful` : Incrémenter le compteur "utile"

### Vérifications
- L'utilisateur doit avoir acheté et reçu le produit pour laisser un avis
- Un seul avis par client et par produit
- Seul le créateur peut modifier/supprimer son avis

## ActiveAdmin

### Interface d'administration
- Menu : "Catalogue" > "Avis Clients"
- Filtres : user, item, rating, status, helpful_count, created_at
- Scopes : all, approved, pending, rejected
- Actions batch : Approuver/Rejeter plusieurs avis
- Actions membres : Approuver/Rejeter un avis individuel

## Vues

### Partielles créées
1. `shared/reviews/_reviews_section.html.erb` : Section complète d'avis avec note moyenne, formulaire et liste
2. `shared/reviews/_review_form.html.erb` : Formulaire de création d'avis avec sélection d'étoiles
3. `shared/reviews/_review_card.html.erb` : Carte d'avis individuelle

### Intégration
- Page produit (`items/show.html.erb`) : Onglet "Avis" avec section complète
- Note moyenne affichée dans l'en-tête du produit
- Formulaire d'avis visible uniquement si l'utilisateur a acheté le produit

## Workflow

1. **Client achète un produit** → OrderItem avec `delivery_status: "delivered"`
2. **Client laisse un avis** → Review créé avec `status: "pending"`
3. **Admin modère l'avis** → Status changé en `approved` ou `rejected`
4. **Note moyenne mise à jour** → Calcul automatique basé sur les avis approuvés
5. **Avis affiché** → Seuls les avis `approved` sont visibles publiquement

## Fonctionnalités

### Pour les clients
- Laisser un avis avec note (1-5 étoiles), commentaire et photos
- Modifier son avis pendant 7 jours après création
- Supprimer son propre avis
- Marquer un avis comme "utile"

### Pour les admins
- Modérer les avis (approuver/rejeter)
- Voir tous les avis avec filtres et scopes
- Gérer les avis en masse (actions batch)

### Automatique
- Calcul de la note moyenne du produit
- Mise à jour automatique lors des changements
- Validation d'unicité (un seul avis par client/produit)

## Prochaines étapes (suggestions)

1. Ajouter des réponses aux avis (pour les boutiques)
2. Système de votes détaillés (utile/pas utile pour chaque avis)
3. Notifications email lors de nouveaux avis
4. Modération automatique basée sur des règles
5. Avis vérifiés (badge "Achat vérifié")
