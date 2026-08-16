# 📋 Documentation: Suppression de la Règle multi_users

**Date**: Janvier 2025
**Raison**: Simplification - `multi_users` était redondant avec `max_employees`
**Impact**: Tous les plans, calculs de capacités, et vues affectées

---

## 🎯 Résumé des Changements

### Avant (Redondant)

```ruby
# Règles
multi_users: boolean (true/false)
max_employees: integer (0, 1, nil)

# Logique
if multi_users? && max_employees > 1 → multi-utilisateurs activé
```

### Après (Simplifié)

```ruby
# Règles
max_employees: integer (1 = solo, nil = illimité/multi)

# Logique
if max_employees.nil? || max_employees > 1 → multi-utilisateurs activé
```

---

## 📝 Fichiers Modifiés

### 1. **db/seeds/shared.rb**

- ✅ Supprimé la création de la règle `multi_users` dans `rules_data`
- 📝 Ajout commentaire: `# NOTE: multi_users a été supprimé - utiliser max_employees > 1`

### 2. **db/seeds/development.rb**

- Mise à jour des 4 plans:
  - **ACCESS**: `multi_users: false, max_employees: 0` → `max_employees: 1`
  - **STARTER**: `multi_users: false, max_employees: 0` → `max_employees: 1`
  - **BUSINESS**: `multi_users: true, max_employees: nil` → `max_employees: nil` ✅ (illimité)
  - **PARTNER**: `multi_users: true, max_employees: nil` → `max_employees: nil` ✅ (illimité)

### 3. **app/domain/shops/capabilities.rb**

```ruby
# Avant
def multi_users?
  @resolver.enabled?("multi_users")
end

# Après
def multi_users?
  max_employees.nil? || max_employees > 1
end
```

### 4. **app/helpers/plans_helper.rb**

```ruby
# Avant
max_employees: plan_rules["max_employees"]&.value || 1,
max_products: plan_rules["max_products"]&.value,
multi_users: plan_rules["multi_users"]&.value || false,

# Après
max_employees: plan_rules["max_employees"]&.value || 1,
max_products: plan_rules["max_products"]&.value,
```

### 5. **docs/setup/PRODUCTION_PLANS_SETUP.md**

- Mise à jour des descriptions de plans
- Suppression des colonnes `multi_users` des tableaux
- Ajout clarification: `max_employees: nil ou >1 = multi-utilisateurs`

### 6. **app/services/phone_normalizer_service.rb** (NOUVEAU)

- Service pour normaliser les numéros de téléphone
- Support 25+ pays africains
- Conversion vers format E.164 et LAM

### 7. **db/migrate/20250105_remove_multi_users_rule_and_plan_rules.rb** (NOUVEAU)

- Migration pour nettoyer en production
- Supprime tous PlanRule + Rule pour `multi_users`

---

## ✅ Points Importants

### 1. **Pas de changement de comportement**

- ❌ Aucun plan ne perd de fonctionnalités
- ACCESS/STARTER restent "solo" (max_employees = 1)
- BUSINESS/PARTNER restent "multi" (max_employees = nil)

### 2. **Vues Affectées (OK)**

Les vues utilisent le helper `multi_users_enabled?(shop)` qui appelle maintenant:

```ruby
shop.capabilities.multi_users?  # ← Retourne toujours le bon booléen
```

✅ Pas besoin de changer les vues

### 3. **Locale (Optionnel)**

- `config/locales/fr/vendors.yml` ligne 516: `multi_users: "Multi-utilisateurs"`
- Cette clé n'est plus utilisée (peut être gardée pour l'historique)

### 4. **Tests**

Vérifier en développement:

```ruby
shop_solo = Shop.assign_plan("ACCESS")
shop_solo.capabilities.multi_users?  # => false ✅

shop_multi = Shop.assign_plan("BUSINESS")
shop_multi.capabilities.multi_users?  # => true ✅
```

---

## 🚀 Déploiement

### Commandes Locales

```bash
# Réinitialiser la DB avec nouvelle structure
rails db:reset

# Vérifier les logs
rails c
> Plan.all.map { |p| [p.code, p.plan_rules.map(&:rule_code)] }
```

### Production (À exécuter APRÈS déploiement du code)

```bash
# La migration supprimera les PlanRule multi_users existantes
rails db:migrate
```

---

## 📌 Gotchas & Notes

1. **Ne pas revenir en arrière** - La migration est destructive (`IrreversibleMigration`)
2. **`max_employees` = 0** était ancien code - Remplacé par `1` partout
3. **Phone Normalization** - Complément: SAV SMS via PhoneNormalizerService
4. **Rules system** - Maintenant 6 règles au lieu de 7 (plus simple)

---

## 📊 Règles Finales (6 Total)

| Règle | Type | Défaut | Notes |
| --- | --- | --- | --- |
| `max_products` | integer | 1 | nil = illimité |
| `max_employees` | integer | 1 | nil = illimité = multi activé |
| `analytics_enabled` | boolean | false | |
| `ai_title_description_enabled` | boolean | true | |
| `ai_background_generation_enabled` | boolean | false | |
| `ai_photo_generation_enabled` | boolean | false | |

---

## 🔗 Fichiers de Référence

- [Rules System](../../app/services/rules/rule_resolver.rb)
- [Capabilities Resolver](../../app/domain/shops/capabilities.rb)
- [Plans Seeds](../../db/seeds/development.rb)
- [Phone Normalizer](../../app/services/phone_normalizer_service.rb)
