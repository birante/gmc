# Grille typographique — aa

Tailles de texte normalisées pour garder une hiérarchie cohérente sur toute la plateforme.

## Usage recommandé

| Rôle | Classe Tailwind | Usage |
|------|-----------------|--------|
| **Titre de page** | `text-2xl font-bold text-gray-900` | H1 auth, titres de section |
| **Sous-titre** | `text-sm text-gray-600` | Sous-titres, descriptions courtes |
| **Label** | `text-sm font-medium text-gray-700` | Labels de champs, libellés |
| **Corps / input** | `text-base` | Champs de formulaire, paragraphes |
| **Bouton** | `text-base font-medium` | Libellés de boutons |
| **Lien secondaire** | `text-sm text-gray-600` + lien `text-[#551694]` | Liens sous formulaires |
| **Caption / hint** | `text-xs text-gray-500` | Astérisque optionnel, aide, légendes |
| **Alerte** | `text-sm` | Messages flash, erreurs, succès |

## Écrans auth

Les écrans d’authentification (vendeurs, clients, collaborateurs) utilisent les partiels partagés :

- `shared/auth/auth_header` — logo, titre, sous-titre (typo normalisée)
- `shared/auth/auth_alert` — flash alert/notice
- `shared/auth/auth_errors` — liste d’erreurs de formulaire

Boutons de soumission : `bg-[#551694] text-white text-base font-medium`, hover `bg-[#451384]`.

## Tokens Tailwind optionnels

Dans `tailwind.config.js`, des alias sont définis : `text-body`, `text-label`, `text-caption`, `text-title`. Tu peux les utiliser en complément des classes `text-sm`, `text-base`, `text-2xl` pour documenter l’intention.
