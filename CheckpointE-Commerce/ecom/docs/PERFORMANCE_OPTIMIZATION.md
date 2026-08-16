# Optimisations de performance - Page d'accueil

## Issues identifiées

### 1. N+1 Query dans `_public_navbar.html.erb` (ligne 189)

**Problème** :
```erb
<% @categories.each do |category| %>
  <%= link_to category.name %>
  <span><%= ProductSubCategory.where(product_category_id: category.id).count %></span>
<% end %>
```

**Solution** :
```ruby
# app/controllers/pages_controller.rb
def home
  @categories = ProductCategory.where(is_active: true)
                                .order(position: :asc)
                                .includes(:product_sub_categories)
  @categories_with_counts = @categories.map { |c| [c, c.product_sub_categories.count] }
end
```

```erb
<% @categories_with_counts.each do |category, count| %>
  <%= link_to category.name %>
  <span><%= count %></span>
<% end %>
```

### 2. Images ActiveStorage - Ahoy overhead

**Problème** : Chaque image GET déclenche `Ahoy::Visit Load`

**Solution** : Disabled Ahoy for asset delivery
```ruby
# config/initializers/ahoy.rb
class Ahoy::Store < Ahoy::BaseStore
  def track_visit(visit)
    # Skip for static assets
    return if controller_path.start_with?('active_storage')
    # ... continue
  end
end
```

### 3. Eager load attachments

**Problème** : Attachments chargés un par un

```ruby
# app/controllers/pages_controller.rb (dans cached_categories)
@categories = ProductCategory.active
                             .includes(:product_sub_categories, 
                                      product_sub_categories: [:icon_attachment])
```

### 4. Recommendations AJAX chargement asynchrone

**Solution** : Defer loading jusqu'après page render
```erb
<!-- app/views/pages/home.html.erb -->
<div id="recommendations-container" data-src="<%= client_items_recommendations_path %>"></div>

<script>
document.addEventListener('turbo:load', () => {
  const container = document.getElementById('recommendations-container');
  if (container) {
    Turbo.visit(container.dataset.src, { replace: container });
  }
});
</script>
```

---

## Checklist optimisations à implémenter

- [ ] Fix N+1 in navbar (ProductSubCategory.count)
- [ ] Eager load all associations in home controller
- [ ] Defer recommendations.js loading
- [ ] Disable Ahoy tracking for ActiveStorage
- [ ] Add HTTP caching headers for images
- [ ] Implement image lazy-loading with `loading="lazy"`
- [ ] Fragment caching for category sections
- [ ] CDN headers for variant images
