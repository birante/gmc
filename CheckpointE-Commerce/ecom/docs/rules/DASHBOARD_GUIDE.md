# Guide d'Implémentation du Dashboard

Ce guide documente l'implémentation du dashboard avec organisation par rôles et permissions.

## 📊 Vue d'ensemble

Le dashboard est organisé selon les rôles et permissions de l'utilisateur connecté. Chaque type d'utilisateur voit un dashboard personnalisé adapté à ses besoins.

## 🎯 Types de Dashboards

### 1. Super Admin Plateforme (`SUPER_ADMIN_PLATFORM`)

**Permissions** : Toutes les permissions (accès global)

**Sections principales** :
- Vue d'ensemble multi-organisations
- Statistiques globales (toutes organisations confondues)
- Gestion des organisations
- Gestion des rôles et permissions
- Audit complet de la plateforme
- Alertes système et sécurité

**Partial** : `app/views/dashboard/_platform_admin.html.erb`

### 2. Super Admin SIRA (`SUPER_ADMIN_SIRA`)

**Permissions** : wallet.read, transaction.read, transaction.validate, settlement.read, liquidity.view, report.export, audit.read

**Sections principales** :
- Vue d'ensemble financière SIRA uniquement
- Transactions nécessitant validation
- KYC en attente de validation
- Settlement et liquidité
- Rapports et exports
- Audit SIRA

**Partial** : `app/views/dashboard/_sira_admin.html.erb`

### 3. Banking Collaboration

**Permissions** : transaction.read, settlement.read, settlement.validate, liquidity.view, report.export, audit.read

**Sections principales** :
- Settlements à valider (priorité)
- Vue liquidité bancaire
- Transactions liées aux settlements
- Rapports et exports
- Audit des opérations bancaires

**Partial** : `app/views/dashboard/_banking.html.erb`

### 4. Compliance Officer

**Permissions** : kyc.view, kyc.validate, audit.read, user.block

**Sections principales** :
- KYC en attente de traitement (priorité)
- Alertes compliance et risques
- Statistiques KYC
- Audit des actions compliance
- Gestion des utilisateurs bloqués

**Partial** : `app/views/dashboard/_compliance.html.erb`

### 5. Customer (Basic/Verified/Full)

**Permissions** : wallet.read, transaction.read (et wallet.debit/credit selon niveau)

**Sections principales** :
- Solde du portefeuille personnel
- Transactions personnelles
- Statut KYC et niveau de vérification
- Historique des transactions
- Actions disponibles selon niveau

**Partial** : `app/views/dashboard/_customer.html.erb`

### 6. Agent (Cashier/Supervisor/Manager)

**Permissions** : wallet.read, wallet.credit, wallet.debit, transaction.read, report.export (selon niveau)

**Sections principales** :
- Transactions du jour (agent)
- Volume et commissions
- Clients gérés
- Rapports (pour supervisor/manager)
- Performance équipe (pour manager uniquement)

**Partial** : `app/views/dashboard/_agent.html.erb`

## 🔧 Implémentation Technique

### Controller

Le `DashboardController` charge les données selon les rôles :

```ruby
# app/controllers/dashboard_controller.rb
def index
  @user = Current.user
  @organization = @user&.profiles&.first&.organization
  @roles = @user&.roles || []
  
  load_dashboard_data
end

private

def load_dashboard_data
  if is_platform_admin?
    load_platform_admin_data
  elsif is_sira_admin?
    load_sira_admin_data
  # ... autres cas
  end
end
```

### Helpers de permissions

Les helpers dans `ApplicationHelper` permettent de vérifier les permissions :

```ruby
# app/helpers/application_helper.rb
def has_permission?(permission_code)
  return false unless Current.user

  Current.user.roles.joins(role_permissions: :permission)
    .where(permissions: { code: permission_code })
    .exists?
end

def is_platform_admin?
  has_role?("SUPER_ADMIN_PLATFORM")
end
```

### Vue principale

La vue principale utilise un switch pour afficher le bon partial :

```erb
<%# app/views/dashboard/index.html.erb %>
<% case @dashboard_type %>
<% when "platform_admin" %>
  <%= render "dashboard/platform_admin" %>
<% when "sira_admin" %>
  <%= render "dashboard/sira_admin" %>
<% # ... autres cas %>
<% end %>
```

## 📋 Checklist d'Implémentation

### Phase 1 : Infrastructure ✅
- [x] Créer helpers pour vérifier les permissions
- [x] Créer helpers pour identifier les rôles
- [x] Mettre à jour `DashboardController` avec logique conditionnelle
- [x] Créer les partials pour chaque type de dashboard

### Phase 2 : Données
- [ ] Implémenter les requêtes pour chaque type de dashboard
- [ ] Ajouter les statistiques réelles (remplacer les valeurs en dur)
- [ ] Implémenter les filtres par organisation
- [ ] Ajouter la pagination pour les listes

### Phase 3 : UI/UX
- [x] Adapter les cards de résumé selon les permissions
- [x] Personnaliser les actions rapides selon les rôles
- [ ] Ajouter des indicateurs visuels pour les alertes
- [x] Implémenter les empty states spécifiques

### Phase 4 : Tests
- [ ] Tests unitaires pour les helpers de permissions
- [ ] Tests d'intégration pour chaque type de dashboard
- [ ] Tests de sécurité (vérifier que les données sont filtrées)

## 🎨 Principes de Design

1. **Hiérarchie visuelle** : Les informations les plus importantes en haut
2. **Cohérence** : Même structure de base pour tous les dashboards
3. **Performance** : Charger uniquement les données nécessaires
4. **Sécurité** : Ne jamais exposer des données non autorisées
5. **Accessibilité** : Maintenir les standards ARIA et sémantiques

## 🚀 Prochaines Étapes

1. **Remplacer les données statiques** par des données réelles (priorité haute)
2. **Implémenter les requêtes** pour chaque type de dashboard (priorité haute)
3. **Ajouter les tests** de sécurité et d'intégration (priorité moyenne)
4. **Optimiser les performances** avec le caching (priorité basse)
