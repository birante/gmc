# Budget Production Hetzner — aa

Document de budgetisation et validation des coûts pour une mise en production sur **Hetzner** (Cloud + Object Storage).  
À utiliser avec le [Guide de Déploiement](DEPLOYMENT_GUIDE.md).

*Prix indiqués TTC 0 % TVA (Hetzner). Dernière mise à jour : mars 2025.*

---

## 1. Tarification Hetzner Cloud (CPX)

| Type   | vCPU | RAM  | Stockage | Trafic | €/h      | €/mois  |
|--------|------|------|----------|--------|----------|---------|
| **cpx32** | 4  | 8 GB  | 160 GB   | 20 TB  | 0,017 € | **10,49 €** |
| **cpx42** | 8  | 16 GB | 320 GB   | 20 TB  | 0,031 € | **19,49 €** |
| **cpx52** | 12 | 24 GB | 480 GB   | 20 TB  | 0,045 € | **27,99 €** |
| **cpx62** | 16 | 32 GB | 640 GB   | 20 TB  | 0,062 € | **38,49 €** |

- Facturation à l’heure, plafonnée au prix mensuel indiqué.
- Trafic sortant inclus : 20 TB/mois ; au-delà : voir [Hetzner Traffic](https://www.hetzner.com/cloud).
- Localisation recommandée : **Falkenstein** ou **Helsinki** (proche Afrique de l’Ouest).

---

## 2. Tarification Object Storage (Buckets)

- **Base** : **4,99 €/mois max** (facturation à l’heure : **0,0081 €/h**).
- **Inclus par heure de runtime** :
  - 1 TB-heure de stockage
  - 1,5 GB de trafic
- **Au-delà** :
  - Stockage : **0,0067 €/TB-heure**
  - Trafic : **1,00 €/TB**
- Objet minimum facturable : **64 kB**.

*Un seul bucket ou plusieurs : la base reste 4,99 €/mois tant que vous restez dans les quotas inclus.*

---

## 3. Redis (cache, sessions, Solid Queue)

Deux options possibles :

### Option 1 — Redis en accessory Kamal (sur le serveur Hetzner)

- **Coût** : **0 €** (même serveur que l’app et PostgreSQL).
- Redis en conteneur (ex. `redis:7-alpine`), ~256–512 MB RAM dédiés.
- Idéal pour cache, sessions, Solid Queue, faible trafic.
- Inclus dans les scénarios ci‑dessous par défaut.

### Option 2 — Redis managé (Redis Cloud Essentials)

- **Coût** : **~5 €/mois** (environ 0,007 €/h, plafonné ~5 $/mois).
- Déploiement partagé, 250 MB à 100 GB RAM & SSD, une base.
- SAML SSO, RBAC, chiffrement en transit et au repos.
- Jusqu’à 99,99 % uptime, support basique.
- **Redis Flex** à 10 % RAM pour le coût le plus bas.
- Utile si vous préférez ne pas gérer Redis sur le serveur ou pour haute dispo.

*Dans les tableaux ci‑dessous, Redis est compté en **option 1** (0 €). Ajouter **+5 €/mois** si vous choisissez l’option 2.*

---

## 4. Scénarios de budget (aller en production tout de suite)

### Scénario A — Minimal (lancement / MVP)

| Poste              | Choix              | Coût mensuel |
|--------------------|--------------------|--------------|
| Serveur app + DB   | 1× **cpx32**       | 10,49 €      |
| Redis              | Accessory Kamal    | 0 €          |
| Object Storage     | 1 bucket (inclus)  | 4,99 €       |
| **Total estimé**   |                    | **~15,50 €/mois** |

- **cpx32** : 4 vCPU, 8 GB RAM — suffisant pour Rails + Puma + PostgreSQL (accessory) + Redis (accessory) si léger.
- Stockage : 160 GB disque local pour OS + app + données ; Active Storage peut rester local ou être branché sur le bucket.

**Idéal pour** : premier déploiement, démo, faible trafic.

---

### Scénario B — Standard (recommandé production)

| Poste              | Choix              | Coût mensuel |
|--------------------|--------------------|--------------|
| Serveur app + DB   | 1× **cpx42**       | 19,49 €      |
| Redis              | Accessory Kamal    | 0 €          |
| Object Storage     | 1 bucket (inclus)  | 4,99 €       |
| **Total estimé**   |                    | **~24,50 €/mois** |

- **cpx42** : 8 vCPU, 16 GB RAM — marge pour pics de charge, jobs, Redis (accessory), backups.
- Même base Object Storage ; trafic et stockage restent dans les inclus pour un usage classique.

**Idéal pour** : production réelle, premiers vrais utilisateurs, enchaînement direct après le guide.

---

### Scénario C — Scale (croissance)

| Poste              | Choix              | Coût mensuel |
|--------------------|--------------------|--------------|
| Serveur app        | 1× **cpx52**       | 27,99 €      |
| Redis              | Accessory Kamal    | 0 €          |
| Object Storage     | 1 bucket (+ dépassement si besoin) | 4,99 € + variable |
| **Total de base**  |                    | **~33 €/mois** |

- **cpx52** : 12 vCPU, 24 GB — pour trafic et jobs plus lourds.
- Option ultérieure : séparer DB sur un 2ᵉ serveur (ex. cpx32 dédié DB) si besoin.

---

### Scénario D — Haute dispo / forte charge

| Poste              | Choix              | Coût mensuel |
|--------------------|--------------------|--------------|
| Serveur app        | 1× **cpx62**       | 38,49 €      |
| Redis              | Accessory Kamal ou managé | 0 € ou +5 € |
| Object Storage     | 1 bucket            | 4,99 €       |
| **Total de base**  |                    | **~43,50 €/mois** (ou ~48,50 € avec Redis managé) |

- **cpx62** : 16 vCPU, 32 GB — pour forte charge ou préparation à un 2ᵉ nœud.

---

## 5. Récapitulatif budget (validation)

| Scénario   | Serveur | Redis | Storage | Total/mois | Usage conseillé        |
|------------|---------|-------|---------|------------|-------------------------|
| **A Minimal**   | cpx32   | 0 € (accessory) | 4,99 €  | **~15,50 €**  | MVP, démo               |
| **B Standard**  | cpx42   | 0 € (accessory) | 4,99 €  | **~24,50 €**  | **Production immédiate** |
| **C Scale**     | cpx52   | 0 € (accessory) | 4,99 €  | **~33 €**     | Croissance              |
| **D Haute charge** | cpx62 | 0 € ou +5 € (managé) | 4,99 €  | **~43,50 €** (ou ~48,50 €) | Fort trafic             |

- Redis en **accessory Kamal** = 0 € (inclus dans le serveur). Redis **managé (Essentials)** = **+5 €/mois**.
- Pas de frais de setup Hetzner.
- Prévoir une petite marge (≈ 5–10 %) pour trafic ou stockage Object Storage au-delà des inclus si usage évolue.

**Budget recommandé pour « aller en production tout de suite » : 25–30 €/mois** (scénario B + Redis accessory + marge).

---

## 6. Checklist production immédiate (Hetzner)

À faire dans l’ordre, en parallèle du [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) :

- [ ] **Compte Hetzner** créé et moyen de paiement validé.
- [ ] **Serveur** : 1× CPX (cpx32 ou cpx42), Ubuntu 24.04, région Falkenstein/Helsinki, firewall 22/80/443.
- [ ] **Redis** : par défaut en accessory Kamal (0 €) ; optionnel Redis managé (~5 €/mois) si besoin.
- [ ] **Bucket** (optionnel au jour 1) : créer si vous utilisez Active Storage S3-compatible tout de suite ; sinon possible en phase 2.
- [ ] **DNS** : enregistrements A (et AAAA si IP v6) vers l’IP du serveur pour le domaine de prod.
- [ ] **Secrets** : `.kamal/secrets` rempli (RAILS_MASTER_KEY, POSTGRES_PASSWORD, etc.) — voir [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md).
- [ ] **Premier déploiement** : `kamal setup` puis `kamal deploy`.
- [ ] **Post-déploiement** : admin initial, seeds, vérif SSL, health check `/up`.

Une fois cette checklist et le guide réalisés, vous êtes en production sur Hetzner avec un budget maîtrisé.

---

## 7. Références

- [Hetzner Cloud](https://www.hetzner.com/cloud) — tarifs et conditions.
- [Hetzner Object Storage](https://www.hetzner.com/storage/object-storage) — buckets et facturation.
- [Guide de Déploiement aa](DEPLOYMENT_GUIDE.md) — étapes détaillées (serveur, DNS, Kamal, vérifications).
