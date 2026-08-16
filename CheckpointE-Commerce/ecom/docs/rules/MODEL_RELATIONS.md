# Relations entre Modèles - SIRA Platform

Ce document décrit toutes les relations entre les modèles de la plateforme SIRA pour garantir la cohérence et faciliter la navigation dans le code.

## 📊 Vue d'ensemble

```
User
├── has_many :profiles
├── has_many :user_roles
├── has_many :roles (through: :user_roles)
├── has_one :kyc
├── has_many :user_identities
├── has_many :user_siracs
├── has_many :sirac_accounts (through: :user_siracs)
├── has_many :wallets (through: :sirac_accounts)
├── has_many :organizations (through: :profiles)
├── has_many :audit_logs
├── has_many :sessions
├── has_many :notifications
├── has_many :report_exports
└── has_many :agent_assignments

Organization
├── has_many :profiles
├── has_many :users (through: :profiles)
├── has_many :roles
├── has_many :user_roles
├── has_many :wallets
├── has_many :transactions
├── has_many :kycs
├── has_many :audit_logs
├── has_many :agent_points
├── has_many :pricing_rules
└── has_many :transaction_limits

SiracAccount
├── has_many :user_siracs
├── has_many :users (through: :user_siracs)
├── has_many :wallets
└── has_many :card_accounts

Wallet
├── belongs_to :sirac_account
├── belongs_to :organization
├── has_many :outgoing_transactions (as from_wallet)
├── has_many :incoming_transactions (as to_wallet)
└── has_many :cards

Transaction
├── belongs_to :organization
├── belongs_to :from_wallet
├── belongs_to :to_wallet
├── has_one :from_sirac_account (through: :from_wallet)
├── has_one :to_sirac_account (through: :to_wallet)
├── has_many :from_users (through: :from_sirac_account)
└── has_many :to_users (through: :to_sirac_account)

Profile
├── belongs_to :user
└── belongs_to :organization

Kyc
├── belongs_to :user
├── belongs_to :organization
└── has_many :kyc_documents

Role
├── belongs_to :organization (optional)
├── has_many :role_permissions
├── has_many :permissions (through: :role_permissions)
├── has_many :user_roles
└── has_many :users (through: :user_roles)
```

## 🔗 Relations Détaillées

### User

**Relations principales :**
- `has_many :profiles` - Un utilisateur peut avoir plusieurs profils (un par organisation)
- `has_many :user_roles` - Assignation de rôles à l'utilisateur
- `has_many :roles, through: :user_roles` - Rôles de l'utilisateur
- `has_one :kyc` - Un seul KYC par utilisateur (mais peut varier par organisation)
- `has_many :user_siracs` - Liens entre utilisateur et comptes SIRAC
- `has_many :sirac_accounts, through: :user_siracs` - Comptes SIRAC de l'utilisateur
- `has_many :wallets, through: :sirac_accounts` - Wallets de l'utilisateur

**Utilisation :**
```ruby
user = User.find(1)
user.profiles # Tous les profils de l'utilisateur
user.sirac_accounts # Tous les comptes SIRAC
user.wallets # Tous les wallets
user.organizations # Toutes les organisations où l'utilisateur a un profil
```

### Organization

**Relations principales :**
- `has_many :profiles` - Profils des utilisateurs dans l'organisation
- `has_many :users, through: :profiles` - Utilisateurs de l'organisation
- `has_many :wallets` - Wallets de l'organisation
- `has_many :transactions` - Transactions de l'organisation
- `has_many :kycs` - KYC des utilisateurs de l'organisation

**Utilisation :**
```ruby
org = Organization.find(1)
org.users # Tous les utilisateurs
org.wallets # Tous les wallets
org.transactions # Toutes les transactions
```

### SiracAccount

**Relations principales :**
- `has_many :user_siracs` - Liens avec les utilisateurs
- `has_many :users, through: :user_siracs` - Utilisateurs ayant accès au compte
- `has_many :wallets` - Wallets associés au compte SIRAC

**Utilisation :**
```ruby
account = SiracAccount.find(1)
account.users # Utilisateurs ayant accès
account.wallets # Wallets du compte
```

### Wallet

**Relations principales :**
- `belongs_to :sirac_account` - Compte SIRAC propriétaire
- `belongs_to :organization` - Organisation du wallet
- `has_many :outgoing_transactions` - Transactions sortantes (from_wallet)
- `has_many :incoming_transactions` - Transactions entrantes (to_wallet)

**Utilisation :**
```ruby
wallet = Wallet.find(1)
wallet.sirac_account # Compte SIRAC
wallet.outgoing_transactions # Transactions sortantes
wallet.incoming_transactions # Transactions entrantes
wallet.sirac_account.users # Utilisateurs ayant accès au wallet
```

### Transaction

**Relations principales :**
- `belongs_to :organization` - Organisation de la transaction
- `belongs_to :from_wallet` - Wallet source
- `belongs_to :to_wallet` - Wallet destination
- `has_one :from_sirac_account, through: :from_wallet` - Compte SIRAC source
- `has_one :to_sirac_account, through: :to_wallet` - Compte SIRAC destination

**Utilisation :**
```ruby
transaction = Transaction.find(1)
transaction.from_wallet # Wallet source
transaction.to_wallet # Wallet destination
transaction.from_sirac_account.users # Utilisateurs du wallet source
transaction.to_sirac_account.users # Utilisateurs du wallet destination
```

## 🎯 Patterns d'Accès Communs

### Obtenir l'utilisateur d'un wallet

```ruby
wallet = Wallet.find(1)
# Via sirac_account
users = wallet.sirac_account.users
# Utilisateur principal (owner)
owner = wallet.sirac_account.users.joins(:user_siracs).where(user_siracs: { role: 'owner' }).first
```

### Obtenir les transactions d'un utilisateur

```ruby
user = User.find(1)
# Toutes les transactions où l'utilisateur est impliqué
transactions = Transaction.joins(from_wallet: { sirac_account: :users })
                         .where(users: { id: user.id })
                         .or(
                           Transaction.joins(to_wallet: { sirac_account: :users })
                                     .where(users: { id: user.id })
                         )
```

### Obtenir le wallet d'un utilisateur pour une organisation

```ruby
user = User.find(1)
organization = Organization.find(1)
wallet = user.wallets.joins(:organization)
             .where(organizations: { id: organization.id })
             .where(wallet_type: 'customer')
             .first
```

## ⚠️ Points d'Attention

1. **Un utilisateur peut avoir plusieurs wallets** (un par organisation et par type)
2. **Un wallet appartient à un seul SiracAccount** mais un SiracAccount peut avoir plusieurs wallets
3. **Les transactions lient deux wallets** (from_wallet et to_wallet)
4. **Les utilisateurs accèdent aux wallets via SiracAccount** (relation indirecte)
5. **Un profil lie un utilisateur à une organisation** avec un type spécifique

## 🔄 Scénarios d'Utilisation

### Créer une transaction entre deux utilisateurs

```ruby
from_user = User.find(1)
to_user = User.find(2)
organization = Organization.find(1)

from_wallet = from_user.wallets.joins(:organization)
                       .where(organizations: { id: organization.id })
                       .where(wallet_type: 'customer')
                       .first

to_wallet = to_user.wallets.joins(:organization)
                   .where(organizations: { id: organization.id })
                   .where(wallet_type: 'customer')
                   .first

Transaction.create!(
  organization: organization,
  from_wallet: from_wallet,
  to_wallet: to_wallet,
  amount: 10000,
  currency: 'XOF',
  transaction_type: 'transfer_internal',
  status: 'pending',
  reference: generate_reference,
  metadata: {}
)
```

### Obtenir tous les clients d'une organisation

```ruby
organization = Organization.find(1)
customers = organization.users.joins(:profiles)
                        .where(profiles: { profile_type: 'CUSTOMER', status: 'active' })
```

### Obtenir le solde total d'un utilisateur

```ruby
user = User.find(1)
total_balance = user.wallets.sum(:balance)
```
