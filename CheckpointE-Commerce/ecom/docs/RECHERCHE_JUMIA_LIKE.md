# Recherche principale type Jumia — Roadmap

> **Objectif :** transformer la recherche actuelle (form + redirect vers `/fr/produits`) en une expérience de recherche moderne type **jumia.sn** : dropdown d'autocomplete avec miniatures produits **+ boutiques**, recherches récentes, suggestions populaires, filtre catégorie intégré, overlay plein écran sur mobile.

**Périmètre de recherche** : produits (`Item`) **et** boutiques (`Shop`). Trois familles de résultats remontent dans le dropdown : **Produits**, **Boutiques**, **Catégories**.

---

## Faisabilité — Verdict

**Oui, faisable, fondations déjà en place.** Backend solide (`pg_search` + `pg_trgm` fuzzy actifs depuis commit `c8730fc`), frontend = page blanche (aucun dropdown, aucun stimulus controller, pas d'API suggestions). Le gros du travail sera UI/JS, pas SQL.

---

## État des lieux (au 2026-04-29)

| Composant | Existant | Manquant |
|---|---|---|
| Recherche full-text produits | `pg_search_scope :search_fuzzy` sur `name`, `slug` (`app/models/item.rb:7-11`) | Ajouter `description`, `meta_title`, `meta_description`, nom catégorie |
| Recherche full-text boutiques | **Aucun** (`app/models/shop.rb` — pas de `pg_search_scope`) | Ajouter scope sur `name`, `slug`, `description` |
| Filtrage | `ItemFiltering` concern (`app/controllers/concerns/item_filtering.rb`) | Suggestions catégories à la volée |
| Endpoint suggestions | Aucun | À créer : `GET /search/suggestions.json?q=...` |
| Input desktop | `app/views/shared/_public_navbar.html.erb:94-111` | Dropdown + stimulus |
| Input mobile | `app/views/shared/_public_navbar.html.erb:254-269` | Overlay plein écran |
| Recherches récentes | Aucun stockage | localStorage côté client |
| Recherches populaires | Aucun tracking | Agrégation depuis `ahoy_events` ou table dédiée |
| Stimulus controller | Aucun pour la recherche | `search_controller.js` |
| Debouncing | Aucun | 200–300 ms côté JS |

---

## Phases (par ordre de valeur livrée)

### Phase 1 — API suggestions (backend) ⏳

- [ ] Étendre `pg_search_scope :search_fuzzy` sur `Item` aux champs `description`, `meta_title`, `meta_description` (poids différents si possible via `tsearch:`)
- [ ] **Ajouter `pg_search_scope :search_fuzzy` sur `Shop`** (champs : `name`, `slug`, `description`) — modèle `app/models/shop.rb`
- [ ] Filtrer les boutiques actives uniquement (vérifier le scope `published`/`active` existant)
- [ ] Nouveau contrôleur `Client::SearchController` ou action `Client::ItemsController#suggestions`
- [ ] Route `GET /:locale/search/suggestions(.json)` (rate-limited, cacheable 30s)
- [ ] Réponse JSON :
  ```json
  {
    "products": [{ "id", "name", "slug", "image_url", "price", "currency_symbol", "category", "shop_name" }],
    "shops":    [{ "id", "name", "slug", "logo_url", "items_count", "city" }],
    "categories": [{ "id", "name", "slug", "match_count" }],
    "query": "..."
  }
  ```
- [ ] Limites : 6 produits + 3 boutiques + 4 catégories max
- [ ] Validation : query ≥ 2 caractères, sinon `[]`
- [ ] Pondération : produits prioritaires, boutiques en 2e bloc, catégories en raccourci de filtre
- [ ] Tests : controller spec + query spec (avec cas mix produits/boutiques)

### Phase 2 — Dropdown autocomplete desktop ⏳

- [ ] `app/javascript/controllers/search_controller.js` (Stimulus)
  - Cibles : `input`, `dropdown`, `productsList`, `shopsList`, `categoriesList`, `recentList`
  - `debounce` (200 ms) sur input
  - Fetch vers `/search/suggestions.json`
  - Gestion clavier : ↑ ↓ Enter Esc
  - Click outside → ferme
- [ ] Mise à jour partial `_public_navbar.html.erb` desktop : wrapper `data-controller="search"` + `<div data-search-target="dropdown">`
- [ ] Highlight des matches dans le nom du produit
- [ ] État vide : « Aucun résultat pour "xyz" »
- [ ] État loading : spinner discret
- [ ] Lien « Voir tous les produits pour "xyz" » → `/fr/produits?search=xyz`
- [ ] Lien « Voir toutes les boutiques pour "xyz" » → `/fr/boutiques?search=xyz` (vérifier que la route + recherche existe sur l'index boutiques, sinon l'ajouter)
- [ ] Click sur une boutique → page boutique (`/:shop_slug`)

### Phase 3 — Recherches récentes (localStorage) ⏳

- [ ] Sauver au submit dans `localStorage["aa:recent_searches"]` (max 5, dédupliqué, FIFO)
- [ ] Afficher les recherches récentes au focus de l'input vide
- [ ] Bouton « Effacer l'historique »
- [ ] Pas de PII envoyée au serveur (pure client-side)

### Phase 4 — Recherches populaires / tendances ⏳

- [ ] Évaluer source : agrégation `ahoy_events` (event `search_performed`) ou table dédiée `popular_searches` rafraîchie en background
- [ ] Endpoint `GET /search/trending.json` (cache 1 h)
- [ ] Affichage dans le dropdown quand input vide ET pas d'historique
- [ ] Tracker chaque recherche via Ahoy (event `search_performed` avec `query`, `results_count`)

### Phase 5 — Filtre catégorie intégré au champ ⏳

- [ ] Select `<select>` à gauche du champ (« Toutes catégories » par défaut)
- [ ] Inclus dans la query string `?category=...&search=...`
- [ ] `Client::ItemsController#index` filtre déjà via `ItemFiltering` — vérifier compat
- [ ] Persistance de la dernière catégorie sélectionnée en localStorage

### Phase 6 — Overlay mobile plein écran ⏳

- [ ] Au tap sur l'input mobile, ouvrir une vue plein écran (modal Stimulus)
- [ ] Header : input + bouton « Annuler »
- [ ] Body : recherches récentes / populaires / résultats live
- [ ] Bloquer scroll du body
- [ ] Animation slide-in
- [ ] Gestion bouton retour navigateur (history.pushState)

### Phase 7 — Polish & perf ⏳

- [ ] Précharger les miniatures produits (`<link rel="preload">` sur les 3 premiers résultats)
- [ ] Mesurer latence p95 endpoint suggestions (< 150 ms cible)
- [ ] Index pg dédiés : `CREATE INDEX items_name_trgm_idx ON items USING gin (name gin_trgm_ops);` + équivalent sur `shops.name` (vérifier qu'ils existent)
- [ ] A/B test : conversion search → click produit avant/après
- [ ] Accessibilité : ARIA combobox, `aria-activedescendant`, focus management
- [ ] i18n : strings dans `config/locales/{fr,en}.yml`

---

## Décisions à trancher avant d'attaquer

1. **Stack** : rester sur `pg_search` (suffisant à notre échelle) ou anticiper Meilisearch/Elasticsearch pour > 100k produits + boutiques ? → pg_search OK pour MVP, réévaluer à 50k items.
1bis. **Périmètre boutiques** : remonter toutes les boutiques actives, ou seulement celles qui ont au moins N produits publiés ? → seuil minimal recommandé pour éviter les boutiques fantômes dans les suggestions.
2. **Recherches populaires** : Ahoy (déjà en place) ou table dédiée ? → Ahoy en agrégat horaire pour commencer.
3. **Catégorie dans le champ** : utile pour Jumia (catalogue énorme) — pertinent à notre stade ? → Phase optionnelle, à shipper si retour utilisateur le demande.
4. **Tracking** : event `search_performed` côté client (sur submit) ou serveur (dans contrôleur) ? → Serveur pour fiabilité.

---

## Risques

- **N+1 sur suggestions** : bien `includes(:main_image_attachment, :currency, :product_sub_category)` dans l'endpoint
- **DDOS suggestions** : rate-limit (Rack::Attack) sur `/search/suggestions` à 30 req/min/IP
- **localStorage XSS** : ne jamais `innerHTML` les recherches récentes — toujours `textContent`
- **Régression SEO** : `/fr/produits?search=...` doit continuer de fonctionner (JSON-LD, meta tags). Le dropdown n'est qu'un raccourci — la page de résultats reste source de vérité

---

## Suivi

- **Branche dédiée** : créer `feature/recherche-jumia-like` au démarrage
- **Issue/PR** : ouvrir une issue mère + PR par phase pour reviews ciblées
- **Cible release** : à définir avec l'équipe

> Mettre à jour ce fichier au fil de l'avancement (cocher les cases, ajouter les décisions prises, lier les PR).
