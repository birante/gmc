# Layered Design – Playbook opérationnel

Ce document est un résumé actionnable du livre "Layered Design for Ruby on Rails Applications".
Il sert de base de connaissance pour comprendre et appliquer l'architecture en couches.

> **Note** : Pour une documentation complète, voir [ARCHITECTURE.md](../ARCHITECTURE.md)

## Chapitre 5 – Services

### Règles
- **Un service = un cas d'usage** - Chaque service représente une action métier complète
- **Orchestration uniquement** - Le service orchestre les appels aux autres couches
- **Pas de HTTP** - Aucune logique HTTP dans les services
- **Pas de SQL** - Aucune requête SQL directe dans les services

### Exemple
```ruby
class CreateTransactionService
  def call
    validate_permissions
    create_transaction
    update_wallet
    log_audit
  end
end
```

## Chapitre 6 – Queries & Repositories

### Règles
- **Query = lecture** - Opérations SELECT uniquement
- **Repository = écriture** - Opérations INSERT, UPDATE, DELETE uniquement
- **Aucun mélange** - Un fichier ne fait jamais les deux

### Séparation stricte
- `app/queries/` - Toutes les lectures
- `app/repositories/` - Toutes les écritures

## Chapitre 7 – Workflows

### Caractéristiques
- **Processus long** - Opérations qui s'étendent sur plusieurs étapes
- **États explicites** - Chaque étape a un état clair
- **Testables isolément** - Chaque étape peut être testée indépendamment

### Exemple
```ruby
class KycValidationWorkflow
  STATES = %w[pending review approved rejected].freeze
  
  def start
    transition_to(:review)
    notify_compliance_team
  end
end
```

## Chapitre 8 – Form Objects

### Règles
- **Validation UI** - Validation côté interface utilisateur
- **ActiveModel** - Utilise ActiveModel::Model
- **Pas d'ActiveRecord** - Ne pas hériter d'ActiveRecord::Base

### Exemple
```ruby
class CreateUserForm
  include ActiveModel::Model
  
  validates :email_address, presence: true
  validates :password, length: { minimum: 8 }
end
```

## Chapitre 13 – IA

### Principes
- **Agents obligatoires** - Encapsuler la logique IA dans des agents dédiés
- **Prompts encapsulés** - Centraliser les prompts dans des classes dédiées
- **Réponses structurées** - Utiliser des structures de données cohérentes

## Principes fondamentaux

1. **Une responsabilité par fichier**
2. **Une couche par fichier**
3. **Dépendances descendantes uniquement**

## Références

- 📚 [ARCHITECTURE.md](../ARCHITECTURE.md) - Documentation détaillée et complète de l'architecture
- 📄 [PDF du livre original](../books/9781806114238-LAYERED_DESIGN_FOR_RUBY_ON_RAILS_APPLICATIONS.pdf) - Source complète
- **Livre source** : "Layered Design for Ruby on Rails Applications" par Vladimir Dementyev
  - Toutes les informations ont été extraites et documentées dans ARCHITECTURE.md
  - Ce playbook sert de référence rapide pour le développement quotidien
