# Guide des tailles d'images — aa

> Ce document liste toutes les images uploadables via l'admin, avec les dimensions recommandées, le format attendu et l'endroit où elles s'affichent sur le site.

---

## 1. Hero Slider (Slides de la page d'accueil)

| Champ | Fichier admin |
|---|---|
| `:image` | `app/admin/hero_slider_slides.rb` |

- **Taille recommandée** : `1280 × 350 px`
- **Format** : JPG, PNG, WebP
- **Affichage** : Carousel hero en haut de la page d'accueil, pleine largeur
- **Hauteur affichée** : `200px` (mobile) → `280px` (sm) → `322px` (md) → `350px` (lg+)
- **Note** : Si aucune image n'est uploadée, le dégradé de fond est utilisé automatiquement.

---

## 2. Bannières Promo (4 colonnes)

| Champ | Fichier admin |
|---|---|
| `:image` | `app/admin/promo_banners.rb` |
| `:overlay_image` | `app/admin/promo_banners.rb` |

### `:image` — Image de fond de la bannière
- **Taille recommandée** : `600 × 430 px`
- **Format** : JPG, PNG
- **Affichage** : Grille 4 colonnes (desktop) / 2 colonnes (mobile) sur la page d'accueil
- **Hauteur affichée** : `140px` (mobile) → `180px` (sm) → `215px` (lg+)

### `:overlay_image` — Image produit décorative (droite)
- **Taille recommandée** : `150 × 180 px`
- **Format** : PNG avec fond transparent obligatoire
- **Affichage** : Superposée à droite de la bannière, en `object-contain`
- **Hauteur affichée** : `100px` (mobile) → `140px` (sm) → `180px` (lg+)

---

## 3. Bannières Secondaires (Grille mosaïque)

| Champ | Fichier admin |
|---|---|
| `:image` | `app/admin/secondary_banners.rb` |

- **Taille recommandée générale** : `1200 × 700 px`
- **Format** : JPG, PNG
- **Affichage** : Grille mosaïque de 5 bannières (desktop) / 2 colonnes de 4 (mobile)

| Position | Dimensions affichées | Taille idéale |
|---|---|---|
| Centre (grande, `row-span-2`) | `600 × 515 px` | `600 × 515 px` |
| Gauche haut, Droite haut, Gauche bas, Droite bas | `600 × 244 px` | `600 × 244 px` |
| Mobile (4 premières) | `pleine largeur × 120 px` | `600 × 120 px` |

---

## 4. Boutiques Locales (Carousel)

| Champ | Fichier admin |
|---|---|
| `:image` | `app/admin/local_shop_banners.rb` |

- **Taille recommandée** : `172 × 172 px` (carré)
- **Format** : JPG, PNG
- **Affichage** : Tuiles dans le carousel "Boutiques locales" de la page d'accueil
- **Hauteur affichée** : `140 × 140 px` (mobile) → `172 × 172 px` (md+), coins arrondis

---

## 5. Bannière latérale (Made in Senegal / Side Banner)

| Champ | Fichier admin |
|---|---|
| `:image` | `app/admin/home_page_section_side_banners.rb` |

- **Taille recommandée** : `312 × 614 px`
- **Format** : JPG, PNG
- **Affichage** : Sidebar gauche dans la section "Boutiques locales"
- **Hauteur affichée** : `400px` (mobile) → `614px` (lg+)

---

## 6. Marques Officielles (Logos)

| Champ | Fichier admin |
|---|---|
| `:image` | `app/admin/official_brand_banners.rb` |

- **Taille recommandée** : `204 × 153 px` (ou `400 × 300 px` pour densité Retina)
- **Format** : PNG avec fond transparent de préférence
- **Affichage** : Carousel "Boutiques officielles", logo centré dans un conteneur
- **Hauteur affichée** : `120px` (mobile) → `153px` (md+), `max-w-[80%] max-h-[80%] object-contain`

---

## 7. Shop Spotlight (Image promo)

| Champ | Fichier admin |
|---|---|
| `:promo_image` | `app/admin/shop_spotlights.rb` |

- **Taille recommandée** : `400 × 500 px` (portrait)
- **Format** : JPG, PNG
- **Affichage** : Colonne gauche de la section "Shop Spotlight" sur la page d'accueil
- **Note** : L'image est redimensionnée automatiquement à `400 × 500 px` (resize_to_limit)

---

## 8. Logo de la Boutique

| Champ | Fichier admin |
|---|---|
| `:logo` | `app/admin/shops.rb` |

- **Taille recommandée** : `400 × 400 px` (carré)
- **Format** : SVG de préférence, PNG transparent en alternative
- **Affichage** : Header de la boutique, cartes produits, page commandes, navigation
- **Taille affichée** : `48px` → `112px` selon le contexte (`object-contain`)
- **Note** : SVG recommandé pour une qualité parfaite à toutes les tailles

---

## 9. Bannière Principale de la Boutique (legacy)

| Champ | Fichier admin |
|---|---|
| `:banner_image` | `app/admin/shops.rb` |

- **Taille recommandée** : `1280 × 400 px`
- **Format** : JPG, PNG
- **Affichage** : Hero banner en haut de la page boutique
- **Hauteur affichée** : `200px` (mobile) → `280px` (md) → `400px` (lg+)
- **⚠️ Méthode ancienne** : Préférer les bannières multiples (voir §10)

---

## 10. Bannières Multiples de la Boutique

| Champ | Fichier admin |
|---|---|
| `:image` | `app/admin/shop_banners.rb` (aussi dans `shops.rb`) |

- **Taille recommandée** : `1200 × 400 px`
- **Format** : JPG, PNG, SVG
- **Affichage** : Bannière(s) pleine largeur sur la page boutique (peut être un carousel)
- **Note** : Plusieurs bannières créent automatiquement un carousel

---

## 11. Header de Page Boutique (statique)

| Champ | Fichier admin |
|---|---|
| `:image` | `app/admin/shop_page_headers.rb` |

- **Taille recommandée** : `1200 × 420 px`
- **Format** : JPG, PNG
- **Affichage** : Image de fond du header statique de la page boutique
- **Hauteur affichée** : `192px` (mobile) → `256px` (sm) → `320px` (md) → `420px` (lg+)

---

## 12. Slides du Header de Boutique (carousel)

| Champ | Fichier admin |
|---|---|
| `:image` | `app/admin/shop_page_header_slides.rb` |

- **Taille recommandée** : `1200 × 420 px`
- **Format** : JPG, PNG
- **Affichage** : Slides du carousel header de la page boutique (même zone que §11)
- **Note** : Plusieurs slides = carousel automatique

---

## 13. Image Marquee (Bandeau défilant)

| Champ | Fichier admin |
|---|---|
| `:marquee_image` | `app/admin/home_page_sections.rb` |

- **Taille recommandée** : `1440 × 60 px` (ou `2880 × 120 px` pour Retina)
- **Format** : JPG, PNG, WebP
- **Affichage** : Bandeau fin pleine largeur (défilant ou statique)
- **Hauteur affichée** : `44px` (mobile) → `51px` (md+)

---

## 14. Image de Catégorie (Cercles explorateur)

| Champ | Fichier admin |
|---|---|
| `:image` | `app/admin/home_page_section_items.rb` |

- **Taille recommandée** : `250 × 250 px` (carré)
- **Format** : JPG, PNG
- **Affichage** : Tuiles circulaires dans la section "Explorer par catégories" (page d'accueil)
- **Taille affichée** : cercle `104 × 104 px` (mobile) → `124 × 124 px` (md+)
- **Note** : Garder le sujet centré — les bords sont rognés par la forme circulaire

---

## 15. Image de Tendance (Grille 2×2)

| Champ | Fichier admin |
|---|---|
| `:image` | `app/admin/home_page_section_group_items.rb` |

- **Taille recommandée** : `400 × 400 px` (carré)
- **Format** : JPG, PNG
- **Affichage** : Grille 2×2 dans chaque carte "Tendances" de la page d'accueil
- **Note** : 4 images par groupe de tendances, affichées en `aspect-square`

---

## 16. Icône de Catégorie Produit

| Champ | Fichier admin |
|---|---|
| `:icon` | `app/admin/product_categories.rb` |

- **Taille recommandée** : `200 × 200 px` (carré)
- **Format** : PNG avec fond transparent
- **Affichage** :
  - Cercle `48px` sur la page liste produits
  - Carte `160px` de hauteur sur les pages boutique
- **Note** : Fond transparent recommandé pour s'intégrer dans les cercles colorés

---

## 17. Icône de Sous-catégorie Produit

| Champ | Fichier admin |
|---|---|
| `:icon` | `app/admin/product_sub_categories.rb` |

- **Taille recommandée** : `400 × 400 px` (carré)
- **Format** : PNG avec fond transparent
- **Affichage** :
  - Cercle `48px–80px` dans la navigation et le mega-menu
  - Carte pleine largeur `160px` de hauteur sur les pages boutique
- **Note** : Taille plus grande que les catégories car aussi utilisée en carte pleine largeur

---

## 18. Photos de Revue / Avis Produit

| Champ | Fichier admin |
|---|---|
| `:images` (multiple) | `app/admin/reviews.rb` |

- **Taille recommandée** : `800 × 800 px` par photo (carré)
- **Format** : JPG, PNG
- **Maximum** : 5 photos par avis
- **Affichage** : Vignettes dans la section avis sur la page produit

---

## Résumé rapide

| Section | Taille recommandée | Format |
|---|---|---|
| Hero Slider | `1280 × 350 px` | JPG / PNG / WebP |
| Promo Banner (fond) | `600 × 430 px` | JPG / PNG |
| Promo Banner (overlay) | `150 × 180 px` | PNG transparent |
| Bannière secondaire (centre) | `600 × 515 px` | JPG / PNG |
| Bannière secondaire (autres) | `600 × 244 px` | JPG / PNG |
| Boutique locale (logo) | `172 × 172 px` | JPG / PNG |
| Bannière latérale | `312 × 614 px` | JPG / PNG |
| Marque officielle (logo) | `204 × 153 px` | PNG transparent |
| Shop Spotlight | `400 × 500 px` | JPG / PNG |
| Logo boutique | `400 × 400 px` | SVG / PNG transparent |
| Bannière boutique (legacy) | `1280 × 400 px` | JPG / PNG |
| Bannières boutique | `1200 × 400 px` | JPG / PNG / SVG |
| Header boutique | `1200 × 420 px` | JPG / PNG |
| Slide header boutique | `1200 × 420 px` | JPG / PNG |
| Bandeau marquee | `1440 × 60 px` | JPG / PNG / WebP |
| Catégorie (cercle) | `250 × 250 px` | JPG / PNG |
| Tendance (grille 2×2) | `400 × 400 px` | JPG / PNG |
| Icône catégorie | `200 × 200 px` | PNG transparent |
| Icône sous-catégorie | `400 × 400 px` | PNG transparent |
| Photo avis produit | `800 × 800 px` | JPG / PNG |
