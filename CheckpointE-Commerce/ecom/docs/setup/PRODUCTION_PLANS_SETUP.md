# Configuration des Plans en Production

## 📋 Guide de Création des Plans via ActiveAdmin

Les plans ne sont **PAS créés automatiquement** en production. Ils doivent être créés manuellement via l'interface ActiveAdmin après le déploiement.

## 🎯 Étapes de Configuration

### Étape 1: Vérifier les Rules

Avant de créer les plans, vérifier que les 7 règles essentielles existent :

```
/admin/rules
```

Règles attendues :
- `max_products` (integer)
- `analytics_enabled` (boolean)
- `max_employees` (integer) - nil ou 1+ : nil/>1 = multi-utilisateurs activé
- `ai_title_description_enabled` (boolean)
- `ai_background_generation_enabled` (boolean)
- `ai_photo_generation_enabled` (boolean)

✅ Ces règles sont créées automatiquement via `rails db:seed` (fichier shared.rb)

---

### Étape 2: Créer les 4 Plans

Aller sur `/admin/plans/new` et créer chaque plan :

#### 1️⃣ aa ACCESS (Gratuit)

```
Code: ACCESS
Name: aa Access
Description: Tester la vente en ligne sans abonnement
Price: 0.00
Billing Period (months): 1
Is Custom: false
Is Active: true
```

**Fonctionnalités incluses :**
- ✅ 10 produits maximum
- ❌ Pas d'analytics
- ❌ Solo uniquement (max_employees = 1)
- ✅ IA: Preview titre/description uniquement

---

#### 2️⃣ aa STARTER

```
Code: STARTER
Name: aa Starter
Description: Commencer à vendre sérieusement
Price: 15000.00
Billing Period (months): 3
Is Custom: false
Is Active: true
```

**Fonctionnalités incluses :**
- ✅ Produits illimités
- ✅ Analytics standard
- ❌ Solo uniquement (max_employees = 1)
- ✅ IA: Preview + Génération en arrière-plan

---

#### 3️⃣ aa BUSINESS

```
Code: BUSINESS
Name: aa Business
Description: Structurer et faire croître une marque
Price: 30000.00
Billing Period (months): 3
Is Custom: false
Is Active: true
```

**Fonctionnalités incluses :**
- ✅ Produits illimités
- ✅ Analytics activé
- ✅ Multi-utilisateurs activé
- ✅ Collaborateurs illimités
- ✅ IA: Toutes les fonctionnalités (Preview + Arrière-plan + Photo)

---

#### 4️⃣ aa PARTNER (Sur Mesure)

```
Code: PARTNER
Name: aa Partner
Description: Partenariat grandes marques – sur mesure
Price: 0.00
Billing Period (months): (laisser vide)
Is Custom: true
Is Active: true
```

**Fonctionnalités incluses :**
- ✅ Tout illimité
- ✅ IA: Toutes les fonctionnalités

---

### Étape 3: Configurer les Plan Rules

Pour **chaque plan**, aller sur `/admin/plan_rules/new` et créer les 7 règles :

#### aa ACCESS

| Rule | Value | Is Active |
|------|-------|-----------|
| max_products | 10 | ✅ |
| analytics_enabled | false | ✅ |
| max_employees | 1 | ✅ |
| ai_title_description_enabled | true | ✅ |
| ai_background_generation_enabled | false | ✅ |
| ai_photo_generation_enabled | false | ✅ |

#### aa STARTER

| Rule | Value | Is Active |
|------|-------|-----------|
| max_products | (vide = illimité) | ✅ |
| analytics_enabled | true | ✅ |
| max_employees | 1 | ✅ |
| ai_title_description_enabled | true | ✅ |
| ai_background_generation_enabled | true | ✅ |
| ai_photo_generation_enabled | false | ✅ |

#### aa BUSINESS

| Rule | Value | Is Active |
|------|-------|-----------|
| max_products | (vide = illimité) | ✅ |
| analytics_enabled | true | ✅ |
| max_employees | (vide = illimité/multi-users) | ✅ |
| ai_title_description_enabled | true | ✅ |
| ai_background_generation_enabled | true | ✅ |
| ai_photo_generation_enabled | true | ✅ |

#### aa PARTNER

| Rule | Value | Is Active |
|------|-------|-----------|
| max_products | (vide = illimité) | ✅ |
| analytics_enabled | true | ✅ |
| max_employees | (vide = illimité/multi-users) | ✅ |
| ai_title_description_enabled | true | ✅ |
| ai_background_generation_enabled | true | ✅ |
| ai_photo_generation_enabled | true | ✅ |

---

## 🔍 Vérification

Après création, vérifier que :

1. **4 plans sont visibles** sur `/admin/plans`
2. **Chaque plan a 7 PlanRules** (visible sur `/admin/plan_rules` filtré par plan)
3. **Les prix sont corrects** (ACCESS = 0, STARTER = 15000, BUSINESS = 30000, PARTNER = 0)

---

## 🚀 Attribution des Plans

### Pour les boutiques de test

Créer une subscription via `/admin/subscriptions/new` :

```
Shop: [Sélectionner la boutique]
Plan: [Sélectionner le plan]
Status: active
Started At: [Date de début]
Ends At: [Date de fin ou vide si illimité]
```

### Vérification des capacités

Tester qu'une boutique avec le plan ACCESS ne peut créer que 10 produits :

```ruby
# Console Rails
shop = Shop.find_by(name: "Boutique Test")
shop.capabilities.max_products # => 10
shop.capabilities.analytics_enabled? # => false
shop.capabilities.can_create_product?(9) # => true
shop.capabilities.can_create_product?(10) # => false
```

---

## 📝 Notes Importantes

- **Ne JAMAIS exécuter** `rails db:seed` en production après la création manuelle des plans
- Les prix peuvent être ajustés directement via `/admin/plans/:id/edit`
- Pour ajouter de nouvelles règles, les créer d'abord dans `/admin/rules` puis les assigner aux plans via `/admin/plan_rules`
- Le helper `rule!(code)` dans les seeds garantit qu'une règle existe avant de l'utiliser

---

## 🔗 Référence Code

Pour voir la configuration exacte des plans utilisée en développement :
- **Plans**: [db/seeds/development.rb](../../db/seeds/development.rb) lignes 400-429
- **PlanRules**: [db/seeds/development.rb](../../db/seeds/development.rb) lignes 438-502
- **Architecture**: [app/domain/shops/capabilities.rb](../../app/domain/shops/capabilities.rb)
- **Résolution**: [app/services/rules/rule_resolver.rb](../../app/services/rules/rule_resolver.rb)
