# Recommandations Infrastructure - aa E-Commerce

## 📊 Analyse des Besoins

### Performance Actuelle (Optimisée)
- **Temps de réponse**: 240ms
- **Queries SQL**: 102 (bien optimisées)
- **Capacité**: 1000 users/jour confortable avec config actuelle

### Profil de Charge
- **1000 users/jour** = ~42 users/heure
- **Pics horaires** = ~150 users/heure = **3-5 concurrent**
- **Pics exceptionnels (promo/marketing)** = 10-20 concurrent
- **Croissance anticipée** = 5000-10,000 users/jour dans 6-12 mois

### Stack Technique
- **Déploiement**: Kamal v2 (Docker)
- **App**: Rails 8, Puma
- **Database**: PostgreSQL 17
- **Cache**: Solid Cache (Redis/local)
- **Queue**: Solid Queue
- **Storage**: ActiveStorage (local ou S3)

---

## 🎯 Recommandations par Provider

### 🟦 Option 1: Hetzner Cloud (⭐ RECOMMANDÉ)

**Pourquoi Hetzner ?**
- ✅ Meilleur rapport qualité/prix en Europe
- ✅ Serveurs puissants avec CPU dédié
- ✅ Bande passante illimitée
- ✅ Datacenter en Europe (Allemagne/Finlande) - bon pour Afrique de l'Ouest
- ✅ Snapshots gratuits
- ✅ Réseau privé gratuit
- ❌ Pas de datacenters en Afrique (latence ~100-150ms depuis Dakar)

#### Configuration Recommandée - Phase 1 (1000-5000 users/jour)

**Serveur Principal (Application + DB)**
```yaml
Type: CPX31 ou CX32
- vCPU: 4 vCores dédiés
- RAM: 8 GB
- SSD: 160 GB
- Trafic: Illimité
- Prix: ~12-15€/mois (~8,000-10,000 FCFA)
```

**Configuration Kamal**:
```yaml
# deploy.yml
servers:
  web:
    hosts:
      - your-server-ip
    options:
      cpus: "3"        # Réserver 3 cores pour app
      memory: "6g"     # 6GB pour app
    env:
      RAILS_MAX_THREADS: 10
      WEB_CONCURRENCY: 2
      DATABASE_POOL: 10

accessories:
  db:
    host: same-server
    options:
      cpus: "1"
      memory: "1.5g"
```

**Capacité Estimée**:
- ✅ 5,000 users/jour: Confortable
- ✅ 10,000 users/jour: Gérable
- ⚠️ 20,000 users/jour: Limite haute

**Budget Total Phase 1**:
- Serveur CPX31: 12€/mois
- Backups automatiques: 2€/mois
- Volume backup: 5€/mois (optionnel)
- **Total: ~15-20€/mois (~10,000-13,000 FCFA)**

---

#### Configuration Recommandée - Phase 2 (10,000-50,000 users/jour)

**Architecture 2-serveurs**

**Serveur 1 - Application**
```yaml
Type: CPX41
- vCPU: 8 vCores dédiés
- RAM: 16 GB
- SSD: 240 GB
- Prix: ~24€/mois (~16,000 FCFA)

Config Kamal:
  WEB_CONCURRENCY: 4
  RAILS_MAX_THREADS: 15
```

**Serveur 2 - Base de Données**
```yaml
Type: CPX31
- vCPU: 4 vCores
- RAM: 8 GB
- SSD: 160 GB
- Prix: ~12€/mois (~8,000 FCFA)

PostgreSQL dédié + Redis
```

**Budget Total Phase 2**:
- App server CPX41: 24€/mois
- DB server CPX31: 12€/mois
- Load Balancer: 5€/mois
- Backups: 5€/mois
- **Total: ~45-50€/mois (~30,000-33,000 FCFA)**

**Capacité Estimée**:
- ✅ 50,000 users/jour: Confortable
- ✅ 100,000 users/jour: Avec optimisations
- ✅ Pics marketing: OK

---

### 🟩 Option 2: DigitalOcean

**Pourquoi DigitalOcean ?**
- ✅ Interface simple, très user-friendly
- ✅ Marketplace avec images pré-configurées
- ✅ Managed PostgreSQL disponible
- ✅ Spaces (S3-like) intégré
- ✅ App Platform pour déploiement simplifié
- ❌ Plus cher que Hetzner
- ❌ Pas de datacenter en Afrique (latence depuis Dakar)

#### Configuration Recommandée - Phase 1

**Droplet Principal**
```yaml
Type: Premium Intel - 4 vCPU
- vCPU: 4 cores
- RAM: 8 GB
- SSD: 160 GB
- Trafic: 5 TB
- Prix: ~48$/mois (~30,000 FCFA)
```

**OU App Platform (Alternative simplifiée)**
```yaml
Type: Professional
- Instances: 2
- RAM: 2GB par instance
- Auto-scaling: Oui
- Prix: ~24$/mois (~15,000 FCFA)
+ Managed DB (4$/mois minimum)
```

**Configuration Kamal**:
Identique à Hetzner, mais ajouter:
```yaml
# Utiliser managed database
env:
  DATABASE_URL: "${DO_DATABASE_URL}"
```

**Budget Total Phase 1** (Droplet classique):
- Droplet 8GB: 48$/mois
- Spaces (Storage): 5$/mois
- Backups: 10$/mois
- **Total: ~63$/mois (~40,000 FCFA)**

**Budget Total Phase 1** (App Platform):
- App Platform Pro: 24$/mois
- Managed DB Basic: 15$/mois
- Spaces: 5$/mois
- **Total: ~44$/mois (~28,000 FCFA)**

---

#### Configuration Recommandée - Phase 2

**Architecture Séparée**

**App Server**
```yaml
Type: Premium Intel - 8 vCPU
- vCPU: 8 cores
- RAM: 16 GB
- Prix: ~96$/mois (~60,000 FCFA)
```

**Managed Database**
```yaml
Type: PostgreSQL - 4GB
- RAM: 4 GB
- vCPU: 2 cores
- Prix: ~60$/mois (~38,000 FCFA)

Avantages:
- Backups automatiques
- Réplication
- Point-in-time recovery
```

**Budget Total Phase 2**:
- App server 16GB: 96$/mois
- Managed DB 4GB: 60$/mois
- Load Balancer: 12$/mois
- Spaces: 5$/mois
- **Total: ~173$/mois (~110,000 FCFA)**

---

### 🟧 Option 3: AWS (Amazon Web Services)

**Pourquoi AWS ?**
- ✅ Le plus scalable de tous
- ✅ Services managed de qualité (RDS, ElastiCache, S3)
- ✅ CDN CloudFront mondial
- ✅ Infrastructure la plus robuste
- ✅ Datacenter Cap Town (Afrique) - bonne latence
- ❌ Plus complexe à configurer
- ❌ Le plus cher
- ❌ Facturation complexe (surprises possibles)

#### Configuration Recommandée - Phase 1

**EC2 Instance (Application)**
```yaml
Type: t3.medium
- vCPU: 2 cores burst
- RAM: 4 GB
- Prix: ~35$/mois (~22,000 FCFA)

OU t3.large (recommandé)
- vCPU: 2 cores
- RAM: 8 GB
- Prix: ~70$/mois (~45,000 FCFA)
```

**RDS PostgreSQL**
```yaml
Type: db.t3.micro
- vCPU: 2 cores
- RAM: 1 GB
- Storage: 20GB SSD
- Prix: ~20$/mois (~13,000 FCFA)

OU db.t3.small (recommandé)
- RAM: 2 GB
- Prix: ~40$/mois (~25,000 FCFA)
```

**ElastiCache Redis** (optionnel)
```yaml
Type: cache.t3.micro
- RAM: 500 MB
- Prix: ~15$/mois (~10,000 FCFA)
```

**S3 + CloudFront**
```yaml
S3 Storage: ~5$/mois
CloudFront CDN: ~10$/mois
```

**Budget Total Phase 1** (Configuration optimale):
- EC2 t3.large: 70$/mois
- RDS db.t3.small: 40$/mois
- ElastiCache: 15$/mois
- S3 + CloudFront: 15$/mois
- Load Balancer: 20$/mois
- **Total: ~160$/mois (~100,000 FCFA)**

---

#### Configuration Recommandée - Phase 2

**Architecture Multi-AZ (Haute Disponibilité)**

**Application Servers (Auto-scaling)**
```yaml
Type: 2x t3.xlarge
- vCPU: 4 cores chacun
- RAM: 16 GB chacun
- Auto-scaling: 2-4 instances
- Prix: ~300$/mois (~190,000 FCFA)
```

**RDS PostgreSQL Multi-AZ**
```yaml
Type: db.m5.large
- vCPU: 2 cores
- RAM: 8 GB
- Multi-AZ: Oui (réplication automatique)
- Prix: ~200$/mois (~125,000 FCFA)
```

**ElastiCache Redis Cluster**
```yaml
Type: cache.m5.large
- RAM: 6.38 GB
- Réplication: Oui
- Prix: ~100$/mois (~65,000 FCFA)
```

**Budget Total Phase 2**:
- EC2 Auto-scaling: 300$/mois
- RDS Multi-AZ: 200$/mois
- ElastiCache: 100$/mois
- S3 + CloudFront: 30$/mois
- ALB: 20$/mois
- **Total: ~650$/mois (~410,000 FCFA)**

---

## 📊 Comparaison Globale

### Phase 1 (1000-5000 users/jour)

| Provider | Config | CPU | RAM | Prix/mois | Prix FCFA |
|----------|--------|-----|-----|-----------|-----------|
| **🏆 Hetzner** | CPX31 | 4 vCores | 8GB | **15€** | **~10,000** |
| DigitalOcean | Droplet 8GB | 4 cores | 8GB | 48$ | ~30,000 |
| DigitalOcean | App Platform | 2x2GB | 4GB | 44$ | ~28,000 |
| AWS | t3.large+RDS | 4 cores | 10GB | 160$ | ~100,000 |

### Phase 2 (10,000-50,000 users/jour)

| Provider | Architecture | Prix/mois | Prix FCFA | Scalabilité |
|----------|--------------|-----------|-----------|-------------|
| **🏆 Hetzner** | 2 serveurs | **45€** | **~30,000** | ⭐⭐⭐ |
| DigitalOcean | 2 serveurs + Managed DB | 173$ | ~110,000 | ⭐⭐⭐⭐ |
| AWS | Multi-AZ | 650$ | ~410,000 | ⭐⭐⭐⭐⭐ |

---

## 🎯 Recommandation Finale

### Pour Démarrage (Budget limité)

**🥇 CHOIX #1: Hetzner CPX31**
```
Serveur: CPX31 (4 vCPU, 8GB RAM)
Prix: 12€/mois (~8,000 FCFA)
Capacité: 5,000-10,000 users/jour
Latence Dakar: ~120ms

✅ Meilleur rapport qualité/prix
✅ Ressources généreuses
✅ Trafic illimité
✅ Snapshots gratuits
```

**Configuration Kamal recommandée**:
```yaml
# config/deploy.yml
service: aa

image: your-registry/aa

servers:
  web:
    hosts:
      - 78.46.xxx.xxx  # Votre IP Hetzner
    labels:
      traefik.http.routers.aa.rule: Host(`aa.com`)
    options:
      cpus: "3"
      memory: "6g"
    env:
      clear:
        RAILS_ENV: production
        RAILS_LOG_LEVEL: info
      secret:
        - RAILS_MASTER_KEY
        - DATABASE_URL
        - REDIS_URL

accessories:
  db:
    image: postgres:17-alpine
    host: same-server
    port: 5432
    env:
      secret:
        - POSTGRES_PASSWORD
    directories:
      - data:/var/lib/postgresql/data
    options:
      cpus: "0.5"
      memory: "1g"
  
  redis:
    image: redis:7-alpine
    host: same-server
    port: 6379
    directories:
      - data:/data
    options:
      cpus: "0.5"
      memory: "512m"

env:
  clear:
    WEB_CONCURRENCY: 2
    RAILS_MAX_THREADS: 10
    DATABASE_POOL: 10
    RAILS_SERVE_STATIC_FILES: true
    SOLID_QUEUE_IN_PUMA: true
```

---

### Pour Croissance Rapide (Budget moyen)

**🥇 CHOIX #1: DigitalOcean App Platform + Managed DB**
```
App Platform: Professional (2 instances)
Database: Managed PostgreSQL 2GB
Prix: 44$/mois (~28,000 FCFA)
Capacité: 10,000-20,000 users/jour

✅ Auto-scaling intégré
✅ Zéro-downtime deployments
✅ DB Managed avec backups
✅ SSL automatique
✅ Simple à gérer
```

**Configuration Kamal** (si préféré vs App Platform):
```yaml
servers:
  web:
    hosts:
      - 165.227.xxx.xxx  # DO Droplet
    env:
      secret:
        - DATABASE_URL  # Pointe vers Managed DB

# Utiliser DO Spaces pour storage
env:
  clear:
    ACTIVE_STORAGE_SERVICE: digitalocean
    DO_SPACES_BUCKET: aa-production
    DO_SPACES_ENDPOINT: https://fra1.digitaloceanspaces.com
    AWS_ACCESS_KEY_ID: xxx  # DO Spaces key
    AWS_SECRET_ACCESS_KEY: xxx
```

---

### Pour Entreprise (Budget confortable + Scaling)

**🥇 CHOIX #1: AWS Multi-région**
```
EC2: t3.large Auto-scaling (2-4 instances)
RDS: db.t3.small Multi-AZ
ElastiCache: Redis cluster
S3 + CloudFront: CDN mondial
Prix: 160$/mois (~100,000 FCFA)
Capacité: 50,000+ users/jour

✅ Infrastructure la plus robuste
✅ Auto-scaling automatique
✅ CDN mondial (faible latence partout)
✅ Backups et réplication auto
✅ Monitoring avancé (CloudWatch)
```

---

## 🚀 Plan de Migration Progressive

### Mois 1-3: Phase Lancement
```
Provider: Hetzner CPX31
Budget: 15€/mois (~10,000 FCFA)
Capacité: 5,000 users/jour
```

### Mois 4-6: Croissance
Si dépassement de 5,000 users/jour:
```
Option A: Upgrade vers Hetzner CPX41 (24€/mois)
Option B: Migrer vers DigitalOcean App Platform (44$/mois)
```

### Mois 7-12: Scale-up
Si dépassement de 20,000 users/jour:
```
Option A: Hetzner 2-serveurs (45€/mois)
Option B: DigitalOcean Managed (173$/mois)
Option C: AWS Multi-AZ (160$/mois)
```

---

## 📋 Checklist Avant Déploiement

### Configuration Serveur
- [ ] Créer serveur sur provider choisi
- [ ] Configurer firewall (ports 80, 443, 22 uniquement)
- [ ] Configurer SSH keys
- [ ] Installer Docker
- [ ] Créer utilisateur deploy (non-root)

### Configuration DNS
- [ ] Pointer domaine vers IP serveur
- [ ] Configurer records A pour www et @
- [ ] Configurer MX records si emails

### Configuration Kamal
- [ ] Copier `config/deploy.yml.example` → `config/deploy.yml`
- [ ] Configurer variables d'environnement
- [ ] Tester connexion: `kamal setup`
- [ ] Premier déploiement: `kamal deploy`

### Monitoring
- [ ] Activer monitoring provider (Hetzner/DO/AWS)
- [ ] Configurer alertes CPU > 80%
- [ ] Configurer alertes RAM > 85%
- [ ] Configurer alertes disk > 80%
- [ ] Installer Hotwire (ou New Relic si budget)

### Backups
- [ ] Activer snapshots automatiques
- [ ] Configurer backup PostgreSQL quotidien
- [ ] Tester restauration backup
- [ ] Configurer S3/Spaces pour ActiveStorage

---

## 💰 Budget Récapitulatif (12 mois)

### Scénario Conservateur (Hetzner)
```
Mois 1-12: CPX31 (12€/mois)
Total année 1: 144€ (~95,000 FCFA)

+ Domaine: 12€/an
+ Backups: 24€/an
+ Total: ~180€/an (~120,000 FCFA)
```

### Scénario Croissance (DigitalOcean)
```
Mois 1-6: App Platform (44$/mois) = 264$
Mois 7-12: Upgrade managed (100$/mois) = 600$
Total année 1: 864$ (~545,000 FCFA)
```

### Scénario Entreprise (AWS)
```
Mois 1-12: Configuration de base (160$/mois)
Total année 1: 1,920$ (~1,200,000 FCFA)
```

---

## 🎓 Recommandation Personnalisée

Basé sur votre profil (e-commerce, croissance rapide potentielle, Kamal):

### ✅ Phase 1 (Lancement): **Hetzner CPX31**
- Budget minimal (~10,000 FCFA/mois)
- Performance excellente
- Trafic illimité = pas de surprise
- Kamal s'intègre parfaitement

### ✅ Phase 2 (Scaling): **DigitalOcean Managed**
- Interface simple
- Managed services réduisent maintenance
- Auto-scaling intégré
- Bon compromis prix/fonctionnalités

### ✅ Phase 3 (Entreprise): **AWS Multi-région**
- Quand budget permet
- Infrastructure mondiale
- Tous les services managed
- Scaling illimité

---

## 📞 Support & Documentation

- Hetzner: https://docs.hetzner.com/cloud/
- DigitalOcean: https://docs.digitalocean.com/
- AWS: https://docs.aws.amazon.com/
- Kamal: https://kamal-deploy.org/

## 🔧 Scripts d'Installation

Je peux créer des scripts d'installation automatisés pour chaque provider si besoin!
