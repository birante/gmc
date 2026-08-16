# Design System - SIRA Platform

Ce document définit les règles de design et les standards UI/UX pour la plateforme SIRA, inspirés des principes de [Refactoring UI](https://www.refactoringui.com/).

## ⚠️ RÈGLE IMPORTANTE : Full Width

**TOUJOURS utiliser `w-full` pour les conteneurs principaux.**
- ❌ **NE PAS utiliser** `max-w-3xl`, `max-w-2xl`, `max-w-xl`, etc. pour limiter la largeur
- ✅ **TOUJOURS utiliser** `w-full` pour permettre l'utilisation de toute la largeur disponible
- Les conteneurs doivent utiliser toute la largeur de l'écran pour une meilleure utilisation de l'espace

**Exception** : Seulement pour les formulaires simples de type "profil" ou "paramètres" où un conteneur centré et limité est approprié.

## Principes fondamentaux

### 1. Hiérarchie visuelle
- **Taille n'est pas tout** : Utilisez le contraste, la couleur et l'espacement pour créer la hiérarchie
- **Ne pas utiliser de texte gris sur fond coloré** : Utilisez plutôt une opacité réduite ou une couleur plus foncée
- **Séparer la hiérarchie visuelle de la hiérarchie documentaire** : Les balises HTML ne dictent pas nécessairement l'apparence

### 2. Espacement et layout
- **Commencer avec trop d'espace blanc** : Il est plus facile de réduire que d'ajouter
- **Établir un système d'espacement** : Utiliser des multiples de 4px (4, 8, 12, 16, 24, 32, 48, 64)
- **Ne pas remplir tout l'écran** : Laisser de l'espace pour respirer
- **Éviter les espacements ambigus** : Utiliser des valeurs cohérentes

### 3. Typographie
- **Établir une échelle de type** : Utiliser des tailles cohérentes (12, 14, 16, 18, 20, 24, 30, 36, 48px)
- **Utiliser de bonnes polices** : Privilégier la lisibilité
- **Garder la longueur de ligne en check** : 45-75 caractères pour le texte principal
- **Baseline, pas center** : Aligner le texte sur la baseline, pas au centre

### 4. Couleurs
- **Utiliser HSL au lieu de HEX** : Plus facile à manipuler et ajuster
- **Définir les nuances à l'avance** : Créer une palette complète avec plusieurs nuances
- **Les gris n'ont pas besoin d'être gris** : Ajouter une teinte subtile (bleu, violet)
- **Accessible ne signifie pas moche** : Respecter les contrastes WCAG tout en gardant un design attrayant

### 5. Profondeur et ombres
- **Émuler une source de lumière** : Consistance dans la direction des ombres
- **Utiliser les ombres pour transmettre l'élévation** : Plus l'ombre est grande, plus l'élément est élevé
- **Les ombres peuvent avoir deux parties** : Ombre proche (petite, foncée) et ombre lointaine (grande, douce)

### 6. Bordures et séparation
- **Utiliser moins de bordures** : Préférer les ombres, les couleurs de fond contrastées, ou l'espacement
- **Ajouter de la couleur avec des bordures d'accent** : Utiliser des bordures colorées subtiles

## Palette de couleurs

### Couleurs principales
```css
/* Violet principal (inspiré de l'image) */
--primary-50: #f5f3ff;
--primary-100: #ede9fe;
--primary-200: #ddd6fe;
--primary-300: #c4b5fd;
--primary-400: #a78bfa;
--primary-500: #8b5cf6;  /* Couleur principale */
--primary-600: #7c3aed;
--primary-700: #6d28d9;
--primary-800: #5b21b6;
--primary-900: #4c1d95;

/* Gris avec teinte (pas purement gris) */
--gray-50: #f9fafb;
--gray-100: #f3f4f6;
--gray-200: #e5e7eb;
--gray-300: #d1d5db;
--gray-400: #9ca3af;
--gray-500: #6b7280;
--gray-600: #4b5563;
--gray-700: #374151;
--gray-800: #1f2937;
--gray-900: #111827;

/* États */
--success: #10b981;
--warning: #f59e0b;
--error: #ef4444;
--info: #3b82f6;
```

## Système d'espacement

Utiliser des multiples de 4px :
- `4px` (1) - Espacement très serré
- `8px` (2) - Espacement serré
- `12px` (3) - Espacement compact
- `16px` (4) - Espacement standard
- `24px` (6) - Espacement confortable
- `32px` (8) - Espacement large
- `48px` (12) - Espacement très large
- `64px` (16) - Espacement section

## Typographie

### Échelle de type
- `text-xs`: 12px
- `text-sm`: 14px
- `text-base`: 16px
- `text-lg`: 18px
- `text-xl`: 20px
- `text-2xl`: 24px
- `text-3xl`: 30px
- `text-4xl`: 36px

### Poids de police
- `font-normal`: 400
- `font-medium`: 500
- `font-semibold`: 600
- `font-bold`: 700

## Composants

### Boutons
- **Primaire** : Fond violet, texte blanc
- **Secondaire** : Fond transparent, bordure violette
- **Danger** : Fond rouge, texte blanc
- **Ghost** : Fond transparent, texte coloré

### Cards
- Fond blanc
- Ombre subtile (shadow-sm)
- Border-radius: 8px
- Padding: 24px

### Formulaires
- Labels au-dessus des champs
- Espacement de 8px entre label et input
- Bordure grise claire par défaut
- Focus: bordure violette avec ring

### Navigation
- Hauteur: 64px
- Fond blanc avec ombre subtile
- Liens actifs: souligné violet
- Espacement horizontal: 24px entre items

## Règles de design

1. **Moins c'est plus** : Éviter la surcharge visuelle
2. **Cohérence** : Utiliser les mêmes patterns partout
3. **Accessibilité** : Contraste minimum 4.5:1 pour le texte
4. **Responsive** : Mobile-first approach
5. **Performance** : Optimiser les images et les assets

## Structure des composants

### Partials partagés

Les composants réutilisables sont organisés dans `app/views/shared/` :

- `_head.html.erb` - Head partagé (meta tags, styles, scripts)
- `_admin_header.html.erb` - Header admin (logo, navigation, user menu)
- `_admin_navigation.html.erb` - Navigation conditionnelle selon permissions
- `_flash_messages.html.erb` - Messages flash (alertes, notices)
- `_country_selector.html.erb` - Sélecteur de pays
- `_tailwind_config.html.erb` - Configuration Tailwind CSS

### Helpers

Les helpers dans `ApplicationHelper` fournissent :

- `nav_link` - Lien de navigation avec état actif
- `has_permission?` - Vérification de permissions
- `navigation_items` - Liste des items de menu selon permissions
- Helpers de rôles : `is_platform_admin?`, `is_sira_admin?`, `is_customer?`, `is_agent?`

## Règles de design

1. **Moins c'est plus** : Éviter la surcharge visuelle
2. **Cohérence** : Utiliser les mêmes patterns partout
3. **Accessibilité** : Contraste minimum 4.5:1 pour le texte, attributs ARIA
4. **Responsive** : Mobile-first approach avec breakpoints Tailwind
5. **Performance** : Optimiser les images et les assets

## Références

- [Refactoring UI](https://www.refactoringui.com/) - Principes de design pour développeurs
- [Tailwind CSS](https://tailwindcss.com/) - Framework CSS utilitaire
- [WCAG Guidelines](https://www.w3.org/WAI/WCAG21/quickref/) - Standards d'accessibilité web
- [Architecture Documentation](./ARCHITECTURE.md) - Architecture en couches de l'application
