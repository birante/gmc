# Documentation Règles & Architecture

Documentation des règles d'architecture, de design et de conventions du projet.

## 📚 Documentation Essentielle

### Architecture & Conventions
- **[ARCHITECTURE.md](./ARCHITECTURE.md)** - Architecture en couches (Layered Design)
- **[RULES_AND_CONVENTIONS.md](./RULES_AND_CONVENTIONS.md)** - Règles de développement, validations, UX/UI
- **[SERVICES_STRUCTURE.md](./SERVICES_STRUCTURE.md)** - Organisation des services par domaines

### Design System
- **[DESIGN_SYSTEM.md](./DESIGN_SYSTEM.md)** - Système de design, palette de couleurs, composants

### Guides Pratiques
- **[DASHBOARD_GUIDE.md](./DASHBOARD_GUIDE.md)** - Guide d'implémentation des dashboards
- **[MODEL_RELATIONS.md](./MODEL_RELATIONS.md)** - Relations entre modèles

### État du Projet
- **[IMPROVEMENTS.md](./IMPROVEMENTS.md)** - Résumé des améliorations (100% conformité atteinte)

### Références
- **[knowledge/layered_design_playbook.md](./knowledge/layered_design_playbook.md)** - Playbook opérationnel
- **[books/9781806114238-LAYERED_DESIGN_FOR_RUBY_ON_RAILS_APPLICATIONS.pdf](./books/9781806114238-LAYERED_DESIGN_FOR_RUBY_ON_RAILS_APPLICATIONS.pdf)** - Livre original

## 🏗️ Architecture

L'application suit une architecture en couches (Layered Design) basée sur les principes du livre "Layered Design for Ruby on Rails Applications" :

- **Services** : Un service = un cas d'usage, orchestration uniquement
- **Queries & Repositories** : Query = lecture, Repository = écriture, aucun mélange
- **Workflows** : Processus longs avec états explicites
- **Form Objects** : Validation UI avec ActiveModel, pas d'ActiveRecord

### Principes fondamentaux

1. **Une responsabilité par fichier**
2. **Une couche par fichier**
3. **Dépendances descendantes uniquement**

> 📖 **Référence** : Toutes les règles et patterns du livre ont été extraites et documentées dans [ARCHITECTURE.md](./ARCHITECTURE.md). Pour approfondir, consultez le livre original "Layered Design for Ruby on Rails Applications" par Vladimir Dementyev.

## 🎨 Design System

Notre design system est basé sur les principes de [Refactoring UI](https://www.refactoringui.com/) :

1. **Hiérarchie visuelle** - Utiliser le contraste, la couleur et l'espacement
2. **Espacement cohérent** - Système basé sur des multiples de 4px
3. **Typographie claire** - Échelle de type cohérente
4. **Couleurs harmonieuses** - Palette HSL avec nuances complètes
5. **Profondeur subtile** - Ombres pour créer la hiérarchie
6. **Moins de bordures** - Préférer les ombres et l'espacement

## 🛠️ Technologies utilisées

- **Rails 8.1** - Framework backend
- **Tailwind CSS** - Framework CSS utilitaire
- **Stimulus** - Framework JavaScript modeste
- **Turbo** - Accélérateur de pages SPA-like

## 📖 Références externes

### Architecture
- **Livre** : "Layered Design for Ruby on Rails Applications" par Vladimir Dementyev
  - 📄 [PDF du livre](./books/9781806114238-LAYERED_DESIGN_FOR_RUBY_ON_RAILS_APPLICATIONS.pdf) - Source originale complète
  - 📚 [ARCHITECTURE.md](./ARCHITECTURE.md) - Documentation extraite et synthétisée
  - ⚡ [Playbook](./knowledge/layered_design_playbook.md) - Référence rapide pour le développement

### Design
- [Refactoring UI](https://www.refactoringui.com/) - Principes de design pour développeurs
- [Tailwind CSS](https://tailwindcss.com/) - Documentation du framework CSS
- [WCAG Guidelines](https://www.w3.org/WAI/WCAG21/quickref/) - Standards d'accessibilité web

## 🤝 Contribution

Lors de l'ajout de nouvelles fonctionnalités :

1. ✅ Respecter l'architecture en couches définie
2. ✅ Suivre le design system
3. ✅ Utiliser les composants réutilisables
4. ✅ Maintenir la cohérence visuelle et architecturale
5. ✅ Documenter les décisions importantes

## 📋 Quick Start

### Pour comprendre l'architecture
1. Lire [ARCHITECTURE.md](./ARCHITECTURE.md) pour une vue complète
2. Consulter [knowledge/layered_design_playbook.md](./knowledge/layered_design_playbook.md) pour une référence rapide

### Pour comprendre le design
1. Lire [DESIGN_SYSTEM.md](./DESIGN_SYSTEM.md) pour les règles complètes
2. Consulter les composants dans `app/views/shared/`

### Pour implémenter un dashboard
1. Lire [DASHBOARD_GUIDE.md](./DASHBOARD_GUIDE.md)
2. Suivre les exemples de partials dans `app/views/dashboard/`
