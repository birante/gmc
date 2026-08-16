# Configuration de la Pagination Analytics

## ✅ Modifications apportées

### 📦 Gem ajoutée
- ✅ `kaminari` (~> 1.2) ajoutée au Gemfile

### 📁 Services mis à jour
- ✅ `app/services/analytics/vendor_analytics_service.rb` - Support pagination (20 éléments/page)
- ✅ `app/services/analytics/employee_analytics_service.rb` - Support pagination (20 éléments/page)

### 🎨 Vues de pagination créées (Tailwind CSS)
- ✅ `app/views/kaminari/_paginator.html.erb`
- ✅ `app/views/kaminari/_page.html.erb`
- ✅ `app/views/kaminari/_prev_page.html.erb`
- ✅ `app/views/kaminari/_next_page.html.erb`
- ✅ `app/views/kaminari/_first_page.html.erb`
- ✅ `app/views/kaminari/_last_page.html.erb`
- ✅ `app/views/kaminari/_gap.html.erb`

### 📄 Vues produits mises à jour
- ✅ `app/views/vendors/analytics/_products.html.erb` - Pagination ajoutée
- ✅ `app/views/employees/analytics/_products.html.erb` - Pagination ajoutée

### ⚙️ Configuration
- ✅ `config/initializers/kaminari_config.rb` - 20 éléments par page par défaut
- ✅ `config/locales/fr.yml` - Traductions françaises pour la pagination

## 🚀 Installation

### Étape 1 : Installer la gem Kaminari

```bash
bundle install
```

Si vous rencontrez des problèmes de certificats SSL, essayez :

```bash
bundle config set --local disable_ssl_verification true
bundle install
# Puis restaurer
bundle config unset disable_ssl_verification
```

### Étape 2 : Redémarrer le serveur

```bash
# Arrêter le serveur (Ctrl+C)
# Puis redémarrer
bin/rails server
# ou
bin/dev
```

## 📊 Fonctionnalités de pagination

### Pour l'onglet "Produits"
- **20 produits par page** par défaut
- Tri par nombre de vues (décroissant)
- Navigation : Premier | Précédent | Pages | Suivant | Dernier
- Affichage du total et de la plage actuelle

### Exemples d'affichage

```
Affichage de 1 à 20 sur 45 produits

[← Précédent] [1] [2] [3] [Suivant →]
```

```
Affichage de 21 à 40 sur 45 produits

[← Précédent] [1] [2] [3] [Suivant →]
```

## 🎨 Style Tailwind CSS

La pagination utilise un design moderne avec Tailwind CSS :
- Boutons avec bordures et hover effects
- Page active en vert (cohérent avec le thème de l'app)
- Texte gris pour les états inactifs
- Responsive design

## 🔧 Personnalisation

### Changer le nombre d'éléments par page

Dans les services `app/services/analytics/*_analytics_service.rb` :

```ruby
PER_PAGE = 20  # Modifier cette valeur
```

Ou dans `config/initializers/kaminari_config.rb` :

```ruby
config.default_per_page = 20  # Valeur globale par défaut
```

### Modifier le style de pagination

Éditer les fichiers dans `app/views/kaminari/` pour personnaliser l'apparence.

## 📝 Utilisation dans d'autres vues

Pour ajouter la pagination ailleurs dans l'application :

```ruby
# Dans le contrôleur
@items = Item.page(params[:page]).per(20)

# Dans la vue
<%= paginate @items %>

# Avec des paramètres personnalisés
<%= paginate @items, 
    params: { tab: 'products' },
    theme: 'tailwind',
    outer_window: 1,
    inner_window: 2 %>
```

## ✅ Tests recommandés

Après installation, tester :
1. ✅ Accéder à l'onglet "Produits" avec plus de 20 produits
2. ✅ Cliquer sur "Suivant" et "Précédent"
3. ✅ Cliquer sur un numéro de page spécifique
4. ✅ Vérifier que les filtres de dates sont conservés lors de la pagination
5. ✅ Vérifier l'affichage sur mobile

## 🐛 Dépannage

### La pagination ne s'affiche pas

Vérifier que :
- Kaminari est bien installé : `bundle list | grep kaminari`
- Le serveur a été redémarré
- Il y a plus de 20 produits dans la boutique

### Erreurs de style

Si les styles ne s'affichent pas correctement :
1. Vérifier que Tailwind CSS compile correctement
2. Redémarrer le serveur Rails
3. Vider le cache du navigateur

### Paramètres perdus lors de la pagination

Vérifier dans les vues que les paramètres sont bien passés :

```erb
<%= paginate @products_stats, 
    params: { tab: 'products', start_date: @start_date, end_date: @end_date } %>
```

## 📚 Documentation Kaminari

- [GitHub](https://github.com/kaminari/kaminari)
- [Wiki](https://github.com/kaminari/kaminari/wiki)
- [Themes](https://github.com/amatsuda/kaminari_themes)

