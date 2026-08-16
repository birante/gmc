# Documentation aaApps

Documentation consolidée du projet aaApps - Plateforme e-commerce multi-tenant Rails 8.

---

## 📚 Table des Matières

1. [Architecture & Règles](#architecture--règles)
2. [Intégration PayDunya](#intégration-paydunya)
3. [Analytics](#analytics)
4. [Configuration & Déploiement](#configuration--déploiement)
5. [Fonctionnalités](#fonctionnalités)

---

## Architecture & Règles

### Architecture en Couches (Layered Design)

Le projet suit une architecture en couches basée sur "Layered Design for Ruby on Rails Applications" :

- **Controllers** : Couche HTTP, délèguent aux services/queries
- **Services** : Orchestration des cas d'usage, pas de SQL direct
- **Queries** : Lecture uniquement (SELECT)
- **Repositories** : Écriture uniquement (INSERT/UPDATE/DELETE)
- **Models** : Domaine métier

**Principe fondamental** : Une responsabilité par fichier, une couche par fichier, dépendances descendantes uniquement.

📖 **Règles complètes** : Voir `docs/rules/ARCHITECTURE.md`

### Design System

- **Full Width** : Toutes les pages utilisent `w-full` (pas de `max-w-*`)
- **Palette HSL** : Couleurs harmonieuses avec nuances
- **Espacement** : Multiples de 4px
- **Typographie** : Échelle cohérente

📖 **Design System complet** : Voir `docs/rules/DESIGN_SYSTEM.md`

### Services Structure

Services organisés par domaines :
- `vendors/` - Services pour les vendeurs
- `employees/` - Services pour les employés
- `checkout/` - Finalisation des commandes
- `notifications/` - Système de notifications
- `payment_services/` - Intégrations paiement
- `sms/` - Service SMS
- `whatsapp/` - Service WhatsApp

📖 **Structure détaillée** : Voir `docs/rules/SERVICES_STRUCTURE.md`

---

## Intégration PayDunya

### Configuration

Variables d'environnement requises :
```
PAYDUNYA_MODE=test|live
PAYDUNYA_MASTER_KEY=...
PAYDUNYA_PRIVATE_KEY=...
PAYDUNYA_TOKEN=...
PAYDUNYA_PUBLIC_KEY=...
PAYDUNYA_STORE_NAME=...
PAYDUNYA_STORE_URL=...
```

### Flux de Paiement

1. Client sélectionne PayDunya dans le checkout
2. `Checkout::FinalizeOrderService` finalise la commande
3. `PaymentServices::PaydunyaHttpService` crée l'invoice
4. Redirection automatique vers PayDunya
5. Retour via `PaydunyaCallbacksController`

### Routes

- `/paydunya/success` - Succès du paiement
- `/paydunya/cancel` - Annulation
- `/paydunya/ipn` - Webhook IPN
- `/paydunya/charge` - Charge directe

📖 **Documentation complète PayDunya** : Voir `docs/PAYDUNYA_INTEGRATION.md`

---

## Analytics

### Configuration

- **Ahoy Matey** : Tracking des événements
- **Chartkick** : Graphiques
- **Amplitude** (optionnel) : Analytics avancés

### Événements Trackés

- Pages visitées
- Produits consultés
- Commandes créées
- Paniers abandonnés

📖 **Configuration Analytics** : Voir `docs/ANALYTICS_SETUP.md`

---

## Configuration & Déploiement

### Technologies

- **Rails 8.0.3** - Framework backend
- **Ruby 3.4.7** - Langage (géré par Mise)
- **PostgreSQL 17** - Base de données
- **Tailwind CSS v4** - Framework CSS
- **Hotwire** (Turbo + Stimulus) - Framework JavaScript
- **Kamal** - Déploiement Docker

### Déploiement

Utilise Kamal pour le déploiement Docker. Configuration dans `.kamal/`.

📖 **Configuration Kamal/PayDunya** : Voir `docs/KAMAL_PAYDUNYA_SETUP.md`

---

## Fonctionnalités

### Multi-User System

- **Clients** (`User`) - Acheteurs sur la plateforme
- **Vendors** (`Vendor`) - Propriétaires de boutiques
- **Employees** (`Employee`) - Employés des boutiques (via `employee_shops`)

### Gestion des Boutiques

- Boutiques locales et officielles
- Multi-boutiques par vendor
- Gestion des employés par boutique
- Analytics par boutique

### Commandes & Paiements

- Panier multi-boutiques
- Zones de livraison
- Créneaux de livraison
- Paiement PayDunya (PAR/PSR)
- Paiement à la livraison
- Webhooks IPN

### Produits

- Variantes avec attributs
- Catégories et sous-catégories
- Enrichissement IA (optionnel)
- Images optimisées
- SEO-friendly URLs

### Finances

- Transactions par boutique (`ShopTransaction`)
- Reversements mensuels (`Payout`)
- Balance des boutiques
- Commissions automatiques

---

## 📁 Documentation Détaillée

Pour plus de détails, consultez le dossier `docs/` :

- **Architecture & Règles** : `docs/rules/`
- **PayDunya** : `docs/PAYDUNYA_*.md`
- **Analytics** : `docs/ANALYTICS*.md`
- **Configuration** : `docs/*_SETUP.md`

---

## 🚀 Quick Start

### Développement

```bash
# Installer les dépendances
bundle install
yarn install

# Configurer la base de données
rails db:create db:migrate db:seed

# Démarrer le serveur
rails server
```

### Tests

```bash
# Tests unitaires
rails test

# Tests d'intégration
rails test:integration
```

---

**Dernière mise à jour** : $(date)
