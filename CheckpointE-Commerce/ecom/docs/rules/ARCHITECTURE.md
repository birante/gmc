# Architecture - SIRA Platform

Ce document définit l'architecture en couches (Layered Design) de la plateforme SIRA, basée sur les principes du livre **"Layered Design for Ruby on Rails Applications"** par Vladimir Dementyev.

> 📖 **Références** :
> - 📄 [PDF du livre original](./books/9781806114238-LAYERED_DESIGN_FOR_RUBY_ON_RAILS_APPLICATIONS.pdf) - Source complète
> - ⚡ [Playbook opérationnel](./knowledge/layered_design_playbook.md) - Référence rapide
> 
> Ce document extrait et synthétise toutes les règles et patterns du livre pour une utilisation pratique dans le projet.

## 🏗️ Principes fondamentaux

### Règles de base

1. **Une responsabilité par fichier** - Chaque fichier a une seule responsabilité claire
2. **Une couche par fichier** - Ne pas mélanger les couches dans un même fichier
3. **Dépendances descendantes uniquement** - Les couches supérieures dépendent des couches inférieures, jamais l'inverse

### Structure des couches

```
┌─────────────────────────────────────┐
│   Controllers (HTTP Layer)          │
├─────────────────────────────────────┤
│   Services (Use Cases)              │
├─────────────────────────────────────┤
│   Queries & Repositories            │
├─────────────────────────────────────┤
│   Models (Domain)                   │
└─────────────────────────────────────┘
```

## 📦 Services

### Règles

- **Un service = un cas d'usage** - Chaque service représente une action métier complète
- **Orchestration uniquement** - Le service orchestre les appels aux autres couches
- **Pas de HTTP** - Aucune logique HTTP dans les services
- **Pas de SQL** - Aucune requête SQL directe dans les services

### Structure

```ruby
# app/services/create_transaction_service.rb
class CreateTransactionService
  def initialize(user:, params:)
    @user = user
    @params = params
  end

  def call
    # Orchestration uniquement
    validate_permissions
    create_transaction
    update_wallet
    log_audit
  end

  private

  def validate_permissions
    # Appel à un autre service ou query
  end

  def create_transaction
    # Appel au repository
  end
end
```

### Conventions

- Nommage : `VerbNounService` (ex: `CreateTransactionService`)
- Un seul point d'entrée : `call` ou `execute`
- Retourne un résultat structuré (success/error)

## 🔍 Queries & Repositories

### Séparation stricte

- **Query** = Lecture uniquement (SELECT)
- **Repository** = Écriture uniquement (INSERT, UPDATE, DELETE)
- **Aucun mélange** - Un fichier ne fait jamais les deux

### Queries

```ruby
# app/queries/user_transactions_query.rb
class UserTransactionsQuery
  def initialize(user:, filters: {})
    @user = user
    @filters = filters
  end

  def call
    Transaction
      .where(user: @user)
      .where(@filters)
      .order(created_at: :desc)
  end
end
```

### Repositories

```ruby
# app/repositories/transaction_repository.rb
class TransactionRepository
  def create(attributes)
    Transaction.create!(attributes)
  end

  def update(transaction, attributes)
    transaction.update!(attributes)
  end

  def delete(transaction)
    transaction.destroy!
  end
end
```

## 🔄 Workflows

### Caractéristiques

- **Processus longs** - Opérations qui s'étendent sur plusieurs étapes
- **États explicites** - Chaque étape a un état clair
- **Testables isolément** - Chaque étape peut être testée indépendamment

### Structure

```ruby
# app/workflows/kyc_validation_workflow.rb
class KycValidationWorkflow
  STATES = %w[pending review approved rejected].freeze

  def initialize(kyc:)
    @kyc = kyc
  end

  def start
    transition_to(:review)
    notify_compliance_team
  end

  def approve(validator:)
    transition_to(:approved)
    update_user_status
    notify_user
  end

  private

  def transition_to(state)
    @kyc.update!(status: state)
  end
end
```

## 📝 Form Objects

### Règles

- **Validation UI** - Validation côté interface utilisateur
- **ActiveModel** - Utilise ActiveModel::Model
- **Pas d'ActiveRecord** - Ne pas hériter d'ActiveRecord::Base

### Structure

```ruby
# app/forms/create_user_form.rb
class CreateUserForm
  include ActiveModel::Model

  attr_accessor :email_address, :phone_number, :full_name, :password

  validates :email_address, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :phone_number, presence: true
  validates :full_name, presence: true
  validates :password, presence: true, length: { minimum: 8 }

  def save
    return false unless valid?

    CreateUserService.new(attributes).call
  end
end
```

## 🎯 Controllers

### Règles

- **Minces** - Logique minimale, délégation aux services
- **HTTP uniquement** - Gestion des requêtes/réponses HTTP
- **Pas de logique métier** - Toute logique métier dans les services

### Structure

```ruby
# app/controllers/transactions_controller.rb
class TransactionsController < ApplicationController
  def create
    result = CreateTransactionService.new(
      user: Current.user,
      params: transaction_params
    ).call

    if result.success?
      redirect_to transactions_path, notice: "Transaction créée"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def transaction_params
    params.require(:transaction).permit(:amount, :recipient_id)
  end
end
```

## 📁 Structure de fichiers

```
app/
  controllers/          # HTTP layer
  services/             # Use cases / Business logic
  queries/              # Read operations
  repositories/         # Write operations
  workflows/            # Long-running processes
  forms/                # Form objects
  models/               # Domain models (ActiveRecord)
  views/                # Templates
  helpers/              # View helpers
```

## ✅ Checklist de développement

Avant de créer un nouveau fichier :

- [ ] Quelle est la responsabilité unique de ce fichier ?
- [ ] Dans quelle couche se trouve-t-il ?
- [ ] Respecte-t-il les dépendances descendantes ?
- [ ] Est-il testable isolément ?
- [ ] Suit-il les conventions de nommage ?

## 🔗 Références

- [Layered Design for Ruby on Rails Applications](./books/9781806114238-LAYERED_DESIGN_FOR_RUBY_ON_RAILS_APPLICATIONS.pdf) - Livre de référence
- [Knowledge Base](./knowledge/layered_design_playbook.md) - Playbook opérationnel
