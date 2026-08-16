# aa — Suivi des demandes du 19 mars

Document de statut technique (codebase `aaapps`). Dernière mise à jour : 23 mars 2026.

## Réalisé (implémenté dans le code)

| Sujet | Statut | Détail |
|--------|--------|--------|
| Recherche produits **et** boutiques | Fait | `ItemsController` + bloc boutiques ; formulaires pointent vers `items_path`. |
| Slide / hero cliquable | Fait | Lien plein écran quand `cta_path` est défini (`shared/storefront/_hero_slider.html.erb`). |
| Bannière mobile responsive | Fait | Ajustements hauteur / `object-*` dans le hero boutique (`shops/sections/_hero_carousel.html.erb`). |
| Panier desktop trop large | Fait | Largeurs max réduites dans `shared/_cart_sheet.html.erb`. |
| Footer (4 liens) | Fait | `shared/_footer.html.erb` : À propos, Service client, CGU, Nos boutiques. |
| « Boutiques locales » → page liste | Fait | Titre de section lié à `local_client_shops_path` (`_local_shops.html.erb`). |
| Commission **par boutique** | Fait | Colonne `shops.commission_rate` ; `FinanceManager` utilise le taux boutique ; formulaire admin boutique. |
| Plan **prix 0** sans Paydunya | Fait | `Vendors::PlansController#plan_requires_payment?` sur `price.positive?`. |
| `Content missing` / fiche produit | Fait | Cartes produit sans formulaire dans un `<a>` (vues grille / boutique). |
| Admin **promo_carousel** | Fait | Garde si section absente + `return` après redirect (`promo_carousel_configurations.rb`). |
| Add-ons admin (menus) | Fait | `menu false` sur `AddOn` / `ShopAddOn`. |
| Commande admin : **lignes modifiables** | Fait | `order_items_attributes` étendu ; `has_many` avec ajout/suppression ; recalcul des totaux via `Order#recalculate_amounts_from_line_items!` et `OrderItem` (`after_commit`). |
| Abonnement : **règles** | Fait | Boutons d’action : édition du plan / liste des overrides `ShopRule` filtrée par boutique (`subscriptions.rb`). |
| **Mots-clés** produit + IA | Fait | Champs `keywords` ; enrichissement IA remplit `keywords` si vide ; prompt JSON inclut une liste `keywords`. |
| **Paiement** par produit | Fait | `cash_on_delivery_disabled` ; `allowed_payment_codes` (texte, codes séparés par virgules) ; validation checkout + filtrage des radios (`FinalizeOrderService`, `client/orders/new`). |
| Formulaire **règles boutique** (new/edit) | Fait | Conteneur + zone de valeur monospace (`shop_rules.rb`). |

## À valider en recette (staging / prod)

- Exécuter les migrations : `20260323120000`, `20260323140000` (déjà passées en local si `db:migrate` OK).
- Tester le checkout avec panier multi-articles et restrictions de paiement (intersection vide = message d’erreur côté serveur).
- Vérifier le hero / carousel avec **vraies** données CMS (liens, images).
- **Statut boutique** (affichage incorrect signalé) : préciser le symptôme (badge, API, page vendeur) — pas de correctif ciblé sans reproduction.

## Encore ouverts ou partiels

| Sujet | Statut | Note |
|--------|--------|------|
| Accès **aa** sans payer (abonnement / feature gating) | À clarifier | Dépend des règles métier (plans, `ShopRule`, middleware vendeur). À traiter dans un ticket dédié avec le flux exact attendu. |
| **Revue** produit exhaustive | Partielle | Voir section « Revue technique » ci-dessous. |

## Revue technique (courte)

**Points positifs**

- Séparation checkout / `FinalizeOrderService` permet d’ajouter des règles métier (paiement) sans toucher au contrôleur en profondeur.
- Commission au niveau `Shop` évite la constante magique pour la compta vendeur.

**Risques / suivis**

- `OrderItem#after_commit :sync_parent_order_totals` recalcule la commande après chaque ligne : acceptable pour la charge actuelle ; à surveiller si volume d’admin explose.
- Restrictions de paiement : les codes doivent **exactement** correspondre aux `radio_button_tag` (documentés dans `Item::CHECKOUT_PAYMENT_CODES` et l’admin).
- Nouvelles lignes de commande en admin : l’admin doit choisir un `item` cohérent avec `shop` / variante (sinon erreurs de validation possibles).

## Fichiers clés récemment touchés

- `app/admin/orders.rb`, `app/models/order.rb`, `app/models/order_item.rb`
- `app/models/item.rb`, `app/models/cart.rb`, `app/admin/items.rb`
- `app/services/checkout/finalize_order_service.rb`, `app/views/client/orders/new.html.erb`
- `app/services/item_ai_enrichment_service.rb`, `app/views/agents/item_enrichment/enrich_product.text.erb`
- `app/admin/subscriptions.rb`, `app/admin/shop_rules.rb`, `app/admin/promo_carousel_configurations.rb`
- `app/admin/add_ons.rb`, `app/admin/shop_add_ons.rb`
- Migrations `db/migrate/20260323120000_*.rb`, `20260323140000_*.rb`
