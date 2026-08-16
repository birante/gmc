# Offre Infrastructure Production — aa

**Document à remettre au client**  
*Option : Forte charge — Mise en production dès le lancement*

---

## 1. Contexte

La mise en production de l’application aa repose sur une infrastructure cloud dédiée, dimensionnée pour **supporter une forte charge** dès le premier jour (trafic élevé, pics d’utilisation, traitements en arrière-plan). L’option retenue évite les surcoûts et les migrations ultérieures liés à un redimensionnement.

---

## 2. Solution retenue : Option Forte charge

L’infrastructure proposée est hébergée chez **Hetzner** (Allemagne/Finlande), avec une configuration **haute performance** :

| Composant | Description | Bénéfice |
|-----------|-------------|----------|
| **Serveur principal** | 16 cœurs virtuels, 32 Go RAM, 640 Go SSD | Application réactive, base de données et traitements métier fluides, marge pour pics de charge |
| **Base de données** | PostgreSQL (sur le même serveur, dédié) | Données sécurisées, performances stables |
| **Cache & files d’attente** | Redis (sur le même serveur, dédié) | Sessions, cache et traitements asynchrones rapides |
| **Stockage fichiers** | Object Storage (1 bucket) — 1 To-heure inclus, trafic inclus | Hébergement des médias et documents (images, pièces jointes, etc.) |

Cette configuration permet de :

- Servir un **nombre important d’utilisateurs simultanés**
- Gérer les **pics de charge** sans dégradation
- Exécuter les **tâches en arrière-plan** (notifications, envois, rapports) sans ralentir l’application
- Préparer une **évolution** vers un second serveur si besoin (haute disponibilité)

---

## 3. Budget mensuel récurrent

Tous les montants sont indiqués **TTC (TVA 0 % selon régime Hetzner)**. Pas de frais de mise en service.

| Poste | Détail | Coût mensuel |
|-------|--------|--------------|
| Serveur (application + base de données + Redis) | 1 serveur CPX62 — 16 vCPU, 32 Go RAM, 640 Go SSD, 20 To trafic inclus | **38,49 €** |
| Stockage fichiers (Object Storage) | 1 bucket — 1 To-heure stockage inclus, 1,5 Go trafic/heure inclus | **4,99 €** |
| **Total infrastructure** | | **43,48 € / mois** |

*Une marge de sécurité d’environ **5 à 10 %** peut être prévue pour d’éventuels dépassements de trafic ou de stockage (facturation au réel chez Hetzner).*

**Budget indicatif à valider avec le client : 45 à 48 € HT / mois** (arrondi pour marge et évolution).

---

## 4. Ce qui est inclus

- **Hébergement** : serveur dédié, base de données PostgreSQL, Redis, reverse proxy avec certificat SSL (HTTPS).
- **Stockage** : espace pour les fichiers et médias (Object Storage), dans les quotas indiqués.
- **Sécurité** : pare-feu (ports 22, 80, 443), chiffrement des connexions, environnement isolé.
- **Disponibilité** : infrastructure conçue pour un usage production (sauvegardes et bonnes pratiques recommandées côté opérationnel).
- **Localisation** : datacenters en Europe (Allemagne / Finlande), adaptés à un usage international (dont Afrique de l’Ouest).

---

## 5. Facturation et engagement

- **Facturation** : directement par Hetzner (carte bancaire ou moyen de paiement enregistré sur le compte client). Les montants indiqués ci-dessus correspondent aux tarifs publics Hetzner (mars 2025).
- **Engagement** : facturation à l’heure, plafonnée au montant mensuel indiqué ; pas d’engagement de durée minimal chez Hetzner.
- **Évolution** : possibilité d’ajouter un second serveur, un Redis managé ou d’autres services selon les besoins futurs (devis sur demande).

---

## 6. Prochaines étapes côté client

Pour activer cette infrastructure :

1. **Création d’un compte Hetzner** et validation du moyen de paiement.
2. **Transmission du nom de domaine** de production et accès DNS (pour pointer le domaine vers le serveur).
3. **Validation de ce document** (option forte charge et budget indiqué).

La mise en place technique (serveur, base de données, Redis, stockage, déploiement de l’application et configuration SSL) sera réalisée par l’équipe projet une fois ces éléments fournis.

---

*Document établi pour la mise en production de aa — Option Forte charge. Tarifs Hetzner susceptibles d’évoluer ; se référer à [hetzner.com](https://www.hetzner.com) pour les grilles à jour.*
