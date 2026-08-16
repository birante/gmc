# Refonte de la fiche produit & sélection des variantes

**Objectif** : faire converger l'expérience de la fiche produit aa vers les standards observés sur les e-commerces matures (référence principale : Babolat), en commençant par la sélection des variantes (couleur × taille).

**Référence externe** : [Exercise Hood Jacket Homme — Babolat](https://www.babolat.com/fr/exercise-hood-jacket-homme/4MP2121.html), [Cotton Tee Lebron Homme — Babolat](https://www.babolat.com/fr/cotton-tee-lebron-homme/6MS26442.html), [Padel Short Homme — Babolat](https://www.babolat.com/fr/padel-short-homme/6MS26062.html).

**Référence interne (état actuel)** : [T-Shirt Lebron — aa](https://sn.aa.com/fr/produits/t_shirt-lebron).

---

## 1. Diagnostic de l'existant

### 1.1 Ce qui est en place

Code analysé : `app/views/client/items/show.html.erb`, `app/views/client/items/_variant_selector.html.erb`, `app/views/client/items/_variants_preview.html.erb`.

Modèles : `Item` (avec `has_one_attached :main_image` + `has_many_attached :images`), `ItemAttribute` (ex : « Couleur », « Taille »), `AttributeValue` (ex : « Noir », « L »), `ItemVariant` (combinaison concrète), `VariantAttributeValue` (jointure).

Le data model est **suffisant** pour une refonte propre — rien à casser côté schéma, on ajoute principalement deux choses (cf. §4).

### 1.2 Ce qui cloche

| # | Problème | Constat |
|---|---|---|
| **P1** | **Pas de sélecteurs indépendants** | On liste toutes les **combinaisons** comme des lignes : `Taille L \| Couleur Noir`, `Taille XL \| Couleur Noir`, `Taille XL \| Couleur Orange`… Cf. `_variant_selector.html.erb:13` qui affiche `variant.display_name` = `"Couleur: Noir \| Taille: L"`. Au-delà de 4 variantes c'est illisible. |
| **P2** | **Pas de pastilles de couleur** | Aucun rendu visuel de la couleur (pas de swatch hex). L'utilisateur lit le mot « Noir ». |
| **P3** | **L'image principale ne change pas** quand on sélectionne une autre couleur (`show.html.erb:9` utilise `@item.display_image` figé). |
| **P4** | **Pas de galerie** : une seule image visible, pas de carousel ni de miniatures (`show.html.erb:7-13`). |
| **P5** | **Pas de deep-link** : la variante sélectionnée n'est pas dans l'URL → on ne peut pas partager « le T-shirt en orange taille XL ». |
| **P6** | **Pas de guide des tailles**. |
| **P7** | **CTA non-sticky sur mobile** : l'utilisateur doit scroller pour ajouter au panier. |
| **P8** | **Rupture = cul-de-sac** : si la variante choisie est en rupture, on cache simplement le bouton (`show.html.erb:100`). Aucune option « Prévenez-moi ». |
| **P9** | **Microcopy faible** : « Choisissez une variante » plutôt que « Choisissez votre taille » / « Choisissez votre couleur ». |
| **P10** | **Aucune section bas de fiche** structurée (description vs caractéristiques techniques vs composition vs livraison). |
| **P11** | **Stocks bruts exposés** : « 2 disponibles » sur chaque combinaison. Babolat ne le fait pas (sauf low-stock < 3). C'est révélateur d'infos business et bruyant visuellement. |

---

## 2. Ce que fait Babolat (observations)

| Aspect | Comportement |
|---|---|
| **Sélecteurs** | Indépendants. **Coloris** d'abord, **Taille** ensuite, puis quantité. Source : ordre DOM constant sur les fiches étudiées. |
| **Pastilles couleur** | Vignettes cliquables, une par variante de couleur. L'élément sélectionné a un ring/outline. |
| **URL** | Change avec un paramètre `dwvar_<sku>_COLOR_DESCRIPTION_ERP=<code>` → deep-link partageable, navigable au bouton « Back ». |
| **Tailles indispo** | Affichées mais barrées/grisées pour la couleur sélectionnée. L'utilisateur voit la gamme complète et comprend pourquoi sa taille manque. |
| **Galerie** | Plusieurs images (face / dos / détails), miniatures à côté ou en dessous, zoom au survol/click. |
| **Guide des tailles** | Lien `[Guide des tailles]` à droite du libellé « Taille ». Ouvre une modal. |
| **Rupture totale** | Le bouton principal devient **« M'avertir de la disponibilité »** + alternative « Trouver un magasin ». |
| **Wording** | « Choisissez votre taille » avant sélection ; « Ajouter » comme CTA principal ; « Coloris : <Nom> » dynamique à côté des swatches. |
| **Bas de fiche** | Sections distinctes : **Description**, **Avantages**, **Caractéristiques techniques** (Sport, Genre, Coupe, Composition % matière). |
| **Stock** | Pas d'affichage d'unités. Just disponible / indisponible. |
| **Réassurance** | Bandeau « Livraison gratuite », « Retours gratuits », « Paiement sécurisé ». |
| **Breadcrumbs** | Accueil > Catégorie > Sous-catégorie > Produit. |

---

## 3. Cible UX (aa)

### 3.1 Layout grand écran (≥ md)

```
┌─────────────────────────────────────────────────────────────┐
│ Accueil > Boutique X > T-shirts > T-Shirt Lebron            │  ← breadcrumb
├──────────────────────────────┬──────────────────────────────┤
│                              │ T-Shirt Lebron               │
│                              │ Vendu par Babolat SN  ★ 4.8  │
│                              │                              │
│   [ IMAGE PRINCIPALE ]       │ 25 000 FCFA                  │
│                              │ ✓ Disponible                 │
│                              │                              │
│                              │ Couleur : Noir               │
│                              │ ( ● ) ( ○ ) ( ○ )            │  ← swatches
│                              │                              │
│                              │ Taille          Guide tailles│
│                              │ [S][M][L][XL][X̶X̶L̶]            │  ← XXL barré
│                              │                              │
│ [▢][▢][▢][▢]  ← thumbnails   │ Quantité  [ − ][ 1 ][ + ]    │
│                              │                              │
│                              │ [    Ajouter au panier    ]  │
│                              │  ♡ Ajouter aux favoris       │
│                              │                              │
│                              │ ▸ Description                │
│                              │ ▸ Caractéristiques           │
│                              │ ▸ Livraison & retours        │
└──────────────────────────────┴──────────────────────────────┘
```

### 3.2 Mobile

- Image en haut, **swipeable** (carousel horizontal, indicateurs en bas).
- Sélecteurs **identiques au desktop** (swatches + taille en boutons).
- **CTA sticky en bas d'écran** dès que l'utilisateur scrolle sous le bloc prix. Le sticky affiche : prix + bouton « Ajouter ».

### 3.3 Règles d'interaction

1. **Au chargement** : variante par défaut sélectionnée (`item.variants.find(&:is_default?)`). Si elle est en rupture, on choisit la première en stock.
2. **Clic sur une couleur** :
   - L'image principale change si la couleur a sa propre image (cf. §4).
   - Les tailles indisponibles pour cette couleur passent en **barré/désactivé**.
   - Si la taille actuellement sélectionnée est dispo dans la nouvelle couleur → garde-la. Sinon → désélectionne et affiche `« Choisissez votre taille »`.
   - L'URL se met à jour : `?variant_id=<id>` (ou `?color=noir&size=l` plus lisible — voir §5).
   - Le prix et le label `« Couleur : Noir »` se mettent à jour.
3. **Clic sur une taille indispo** : pas de bloquage dur ; on affiche un message inline `« Pas disponible dans cette couleur — essayez Orange »` (le « Orange » est cliquable et switche).
4. **Variante entièrement en rupture** : le CTA principal devient **« M'avertir quand disponible »** (capture email/SMS, cf. P1 du backlog auth).
5. **Aucune sélection complète** : le bouton « Ajouter » reste actif visuellement mais affiche un message si on clique sans avoir choisi taille obligatoire. Alternative : disabled tant que la combinaison n'est pas complète — **recommandé**.
6. **Pas d'affichage du stock brut**. Sauf si stock ≤ 3 : badge `« Plus que 2 — commandez vite »`. Cohérent avec P11.

---

## 4. Évolutions data model

Minimum viable, sans casser l'existant.

### 4.1 Hex sur `AttributeValue`

Aujourd'hui `AttributeValue` a juste `value: "Noir"`. Pour rendre une pastille, il faut une couleur. On ajoute deux champs **optionnels** :

```ruby
# migration
add_column :attribute_values, :hex_color, :string   # "#000000" — utilisé pour les attributs de type couleur
add_column :attribute_values, :swatch_image, :string # alternative pour multi-couleur / motif (URL ou attachment)
```

Heuristique : si `item_attribute.name == "Couleur"` et `hex_color` présent → swatch CSS uni. Si `swatch_image` présent → swatch image. Sinon → pastille texte (« N » pour « Noir »).

Alternative + propre : ajouter une colonne `kind` à `ItemAttribute` (`text`, `color`, `size`) qui pilote le rendu. À discuter selon ambition.

### 4.2 Images par variante (ou par valeur de couleur)

Aujourd'hui les images sont sur `Item`. Pour qu'une couleur ait son image, deux options :

| Option | Avantages | Inconvénients |
|---|---|---|
| **A — `has_many_attached :images` sur `ItemVariant`** | Granularité maximale (une image par combinaison) | Le vendeur doit uploader N×M images |
| **B — `has_many_attached :images` sur `AttributeValue` (couleur)** | Une seule image par couleur, partagée toutes tailles | Limité aux couleurs (mais c'est le besoin réel) |

**Recommandation : B**, plus simple à administrer pour les vendeurs. Fallback sur `item.images` si la couleur n'a pas d'image dédiée.

Helper côté affichage :

```ruby
def variant_image(variant)
  color_value = variant.attribute_values.joins(:item_attribute)
                       .find_by(item_attributes: { name: "Couleur" })
  color_value&.images&.first&.presence || variant.item.display_image
end
```

### 4.3 Notification de disponibilité

Nouvelle table `stock_notifications` :

```
item_variant_id : bigint
contact         : string  # email ou phone (cf. memoire SMS-first)
channel         : enum    # :sms | :email
notified_at     : datetime nullable
```

Hook : après-`update` sur `ItemVariant`, si stock passe à > 0, envoyer aux pending.

---

## 5. URL & deep-linking

Deux schémas viables :

- **Simple** : `?variant_id=123` — facile à implémenter, opaque (pas SEO-friendly).
- **Sémantique** : `?color=noir&size=l` — partageable, lisible, mais demande de matcher les slugs côté contrôleur.

**Recommandation** : commencer par `?variant_id=`, prévoir une migration plus tard si on veut du SEO. Le contrôleur `client/items#show` lit le param et sélectionne la variante au render initial — pas de double round-trip.

---

## 6. Mécanique technique

### 6.1 Côté serveur — `client/items#show`

- Charger toutes les variantes avec leurs `attribute_values` (préchargement `includes` pour éviter N+1, cf. commit `e4c220d` récent).
- Construire un **hash JSON exposé au front** :

```ruby
@variants_payload = @item.variants.map do |v|
  {
    id: v.id,
    sku: v.sku,
    price_cents: v.current_price * 100,
    original_price_cents: v.original_price * 100,
    in_stock: v.in_stock?,
    low_stock: v.in_stock? && v.stock_quantity <= 3,
    image_url: variant_image_url(v),
    attrs: v.attribute_display_hash  # { "Couleur" => "Noir", "Taille" => "L" }
  }
end
```

- Et la matrice de dispo : `attribute_value_id → ids des variantes qui le contiennent` → permet de griser les tailles indispo.

### 6.2 Côté front — Stimulus controller

Un seul controller `variant_selector_controller.js` qui :
- Garde l'état `{ color: 'noir', size: 'l' }`.
- À chaque changement, recalcule la variante correspondante (lookup dans `@variants_payload`).
- Update : image principale, prix, stock badge, état des tailles (disabled si la combinaison color+size n'existe pas / hors stock), input caché `item_variant_id`, URL via `history.replaceState`.

Aucun appel Turbo Frame nécessaire — le payload est dans le DOM au chargement. Léger, snappy.

### 6.3 Galerie d'images

Stimulus controller `gallery_controller.js` qui gère :
- Click sur miniature → swap image principale.
- Carousel horizontal swipeable sur mobile (CSS scroll-snap).
- Zoom au click desktop (modal lightbox simple).

---

## 7. Bas de fiche : sections structurées

Reprendre le découpage Babolat — **3 onglets ou 3 accordéons** :

1. **Description** — texte long du vendeur (`item.description`).
2. **Caractéristiques** — table clé/valeur à partir de `item.product_attributes` + ses valeurs (matière, coupe, sport, etc.). Format Babolat : `Sport : Tennis`, `Coupe : Regular`, `Composition : 80% Coton, 20% Polyester`.
3. **Livraison & retours** — généré depuis la config boutique (`shop.delivery_zones`, politique retours).

Bandeau de réassurance sous les CTA : `🚚 Livraison Dakar • 🔄 Retour 7 jours • 🔒 Paiement sécurisé`.

---

## 8. Microcopy (FR)

| Contexte | Wording |
|---|---|
| Sélecteur couleur | `Couleur : Noir` (le nom est dynamique) |
| Sélecteur taille | `Taille` + lien `Guide des tailles →` à droite |
| Pas de taille choisie | Placeholder `Choisissez votre taille` |
| Taille indispo | tooltip `Indisponible en Noir` |
| Stock bas | `Plus que 2 — commandez vite` |
| Rupture totale | `Indisponible` + CTA `M'avertir quand dispo` |
| CTA principal | `Ajouter au panier` |
| Wishlist | `Ajouter aux favoris` |

---

## 9. Plan de livraison (phasable)

**Phase 1 — Refonte UI sans changement data** (1-2 jours)
- Refondre `client/items/show.html.erb` : layout 2 colonnes, breadcrumb, microcopy, sections accordéons en bas.
- Remplacer `_variant_selector.html.erb` : grouper par attribut (`item.item_attributes.ordered.each`), un sélecteur par attribut. Boutons taille rectangulaires. Pastilles couleur basées sur lookup statique tant qu'il n'y a pas de `hex_color` en DB.
- Construire `@variants_payload` côté contrôleur + Stimulus pour la sélection client-side.
- CTA sticky mobile (CSS `position: sticky`).
- Cacher l'affichage du stock brut sauf si ≤ 3.

**Phase 2 — Galerie & deep-link** (1 jour)
- `gallery_controller.js` (carousel + miniatures).
- Lecture de `?variant_id=` dans `items_controller#show`.
- Update URL via `history.replaceState` sur changement.

**Phase 3 — Data model & images par couleur** (2-3 jours)
- Migrations : `hex_color`, `swatch_image` sur `attribute_values` + `has_many_attached :images` sur `attribute_value` (couleurs).
- UI vendor pour uploader images par couleur (`vendors/items/_product_sheet.html.erb` à étendre).
- Helper `variant_image` + remplacement dans show.

**Phase 4 — Features secondaires**
- Modal « Guide des tailles » (data par catégorie).
- Notify-me (`stock_notifications` + worker SMS, cohérent avec la stratégie SMS-first).
- Cross-sell « Vous aimerez aussi » (réutiliser le système de recommandations existant).
- Wishlist (favoris) — si pas déjà couvert ailleurs.

---

## 10. Points d'attention

- **N+1** : préloader `variants → variant_attribute_values → attribute_value → item_attribute` dans `items_controller#show` (cohérent avec le travail récent de chasse aux N+1, commit `e4c220d`).
- **Catalogue / liste** : `_variants_preview.html.erb` (sur les cartes catalogue) doit aussi afficher des mini-pastilles couleurs (ex : `● ● ●` cliquables qui mènent à la fiche pré-filtrée via `?variant_id=`). Petit gain UX énorme.
- **Accessibilité** : `role="radiogroup"` + `role="radio"` pour les sélecteurs, focus visible, labels ARIA `aria-label="Couleur Noir"`, état `aria-disabled="true"` sur les tailles indispo.
- **Tests** : couvrir avec un test système (Capybara) la sélection croisée couleur→taille→stock low. Attention au blocage local `pg_trgm` ; cf. mémoire — exécuter en CI plutôt que `bin/rails test` local.
- **i18n** : tous les wordings via `t(...)` dans `config/locales/client.fr.yml` et `client.en.yml`.

---

## 11. Hors scope (à noter pour plus tard)

- Configurateur produit (ex : raquettes avec cordage personnalisé).
- Variantes liées (ex : « assortir avec ce short »).
- AR / try-on.
- Notation/avis structurés (existe ? à vérifier).
