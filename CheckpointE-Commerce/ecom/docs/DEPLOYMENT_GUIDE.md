# Guide de Déploiement Rapide - aa

## 🚀 Déploiement en 15 Minutes

**Budget Hetzner** : voir [Production & Budget Hetzner](PRODUCTION_BUDGET_HETZNER.md) pour les prix (CPX, Object Storage) et les scénarios de budget (~15–45 €/mois).

### Prérequis

- [ ] Compte créé sur provider choisi (Hetzner/DigitalOcean/AWS)
- [ ] Nom de domaine configuré (aa.com)
- [ ] Docker installé localement
- [ ] Kamal installé: `gem install kamal`

---

## Option A: Hetzner Cloud (Recommandé - Budget limité)

### 1. Créer le Serveur

```bash
# Sur Hetzner Cloud Console
1. Créer projet "aa Production"
2. Créer serveur:
   - Type: CPX32 (4 vCPU, 8 GB RAM) — voir [PRODUCTION_BUDGET_HETZNER.md](PRODUCTION_BUDGET_HETZNER.md) pour les autres types (cpx42, cpx52, cpx62)
   - Location: Falkenstein, Germany (le plus proche Afrique Ouest)
   - Image: Ubuntu 24.04
   - SSH Key: Ajouter votre clé publique
   - Firewall: Créer et autoriser ports 22, 80, 443
3. Noter l'IP publique: 78.46.xxx.xxx
```

### 2. Setup Initial du Serveur

```bash
# Depuis votre machine locale
scp script/setup_server.sh root@78.46.xxx.xxx:/root/
ssh root@78.46.xxx.xxx

# Sur le serveur
chmod +x setup_server.sh
sudo ./setup_server.sh

# Suivre les instructions (15-20 minutes)
```

### 3. Configurer DNS

```bash
# Chez votre registrar de domaine
A    @              78.46.xxx.xxx
A    www            78.46.xxx.xxx
```

### 4. Préparer Variables d'Environnement

```bash
# Sur votre machine locale
cd /path/to/aa

# Copier template
cp config/deploy.hetzner.yml config/deploy.yml

# Éditer et remplacer:
# - 78.46.xxx.xxx par votre vraie IP
# - your-registry par votre registry Docker

# Créer fichier secrets
cat > .kamal/secrets <<EOF
KAMAL_REGISTRY_PASSWORD=<votre_token_github_ou_dockerhub>
RAILS_MASTER_KEY=$(cat config/master.key)
SECRET_KEY_BASE=$(rails secret)
POSTGRES_PASSWORD=$(openssl rand -hex 32)
DATABASE_URL=postgres://aa:VOTRE_PASSWORD@db:5432/aa_production
REDIS_URL=redis://redis:6379/0
EOF

chmod 600 .kamal/secrets
```

### 5. Premier Déploiement

```bash
# Setup infrastructure (première fois seulement)
kamal setup

# Déployer l'application
kamal deploy

# Vérifier
curl https://aa.com
```

### 6. Configuration Post-Déploiement

```bash
# Créer admin initial
kamal app exec --interactive "bin/rails console"
# Dans console Rails:
Admin.create!(email: 'admin@aa.com', password: 'ChangeMe123!')

# Charger seed data
kamal app exec "bin/rails db:seed"
```

**✅ Déploiement terminé! Site accessible sur https://aa.com**

---

## Option B: DigitalOcean (Recommandé - Interface simple)

### 1. Créer le Droplet

```bash
1. Créer compte DigitalOcean
2. Créer Droplet:
   - Type: Premium Intel 8GB
   - Datacenter: Frankfurt (Europe)
   - Ubuntu 24.04
   - Add SSH Keys
3. Noter IP: 165.227.xxx.xxx
```

### 2. Créer Managed Database (Optionnel mais recommandé)

```bash
1. Databases → Create Database Cluster
2. Type: PostgreSQL 15
3. Plan: Basic (15$/mois)
4. Datacenter: Frankfurt (même que droplet)
5. Noter connection string
```

### 3. Setup Serveur

```bash
# Identique à Hetzner
scp script/setup_server.sh root@165.227.xxx.xxx:/root/
ssh root@165.227.xxx.xxx
chmod +x setup_server.sh && sudo ./setup_server.sh
```

### 4. Configurer Spaces (Storage S3-compatible)

```bash
# Sur DigitalOcean Console
1. Spaces → Create Space
2. Name: aa-production
3. Region: Frankfurt
4. Enable CDN
5. Create API Key (Access + Secret)
```

### 5. Variables d'Environnement

```bash
cp config/deploy.digitalocean.yml config/deploy.yml

# Éditer avec vos valeurs
cat > .kamal/secrets <<EOF
DIGITALOCEAN_ACCESS_TOKEN=<votre_token_DO>
KAMAL_REGISTRY_PASSWORD=<votre_token>
RAILS_MASTER_KEY=$(cat config/master.key)
SECRET_KEY_BASE=$(rails secret)
DATABASE_URL=<connection_string_managed_db>
REDIS_URL=redis://redis:6379/0
DO_SPACES_ACCESS_KEY_ID=<votre_key>
DO_SPACES_SECRET_ACCESS_KEY=<votre_secret>
EOF
```

### 6. Déployer

```bash
kamal setup
kamal deploy
```

---

## Option C: AWS (Pour Entreprise)

### 1. Configuration AWS CLI

```bash
# Installer AWS CLI
brew install awscli  # macOS
# ou: apt install awscli  # Linux

# Configurer
aws configure
# Entrer: Access Key ID, Secret, Region (eu-west-1)
```

### 2. Créer Infrastructure

```bash
# EC2 Instance
1. Launch Instance
2. AMI: Ubuntu 24.04
3. Type: t3.large (2 vCPU, 8GB)
4. Storage: 50GB GP3
5. Security Group: 22, 80, 443
6. Key pair: Créer ou utiliser existante

# RDS PostgreSQL
1. Create Database
2. Engine: PostgreSQL 15
3. Template: Free tier ou Production
4. Instance: db.t3.small
5. Storage: 20GB
6. Security Group: Autoriser depuis EC2
```

### 3. Setup et Déploiement

```bash
# Similaire aux autres providers
# Utiliser IP publique EC2 pour deploy.yml
```

---

## 🔍 Vérifications Post-Déploiement

### 1. Tests Fonctionnels

```bash
# Homepage
curl -I https://aa.com
# Attendu: HTTP/2 200

# API Health
curl https://aa.com/up
# Attendu: OK

# SSL
curl -vI https://aa.com 2>&1 | grep "SSL certificate verify ok"
```

### 2. Tests Performance

```bash
# Depuis votre machine
./script/benchmark.sh light

# Attendu:
# - Temps moyen < 500ms
# - 0 requêtes échouées
```

### 3. Monitoring

```bash
# SSH sur le serveur
ssh deploy@VOTRE_IP

# Vérifier logs
kamal app logs

# Vérifier containers
docker ps

# Vérifier ressources
htop
docker stats
```

### 4. Backups

```bash
# Configurer backups automatiques

# Hetzner: Activer snapshots dans console (1€/mois)
# DigitalOcean: Activer backups dans droplet settings
# AWS: Configurer snapshot lifecycle

# Test backup manuel
kamal app exec "bin/rails db:backup:create"
```

---

## 📋 Checklist de Sécurité

- [ ] Firewall configuré (seulement 22, 80, 443)
- [ ] Fail2ban actif contre brute-force SSH
- [ ] Utilisateur deploy (non-root) pour déploiements
- [ ] SSL/TLS configuré (Let's Encrypt via Traefik)
- [ ] Secrets stockés dans .kamal/secrets (gitignored)
- [ ] RAILS_MASTER_KEY jamais committé
- [ ] Database password fort (32+ caractères)
- [ ] Backups automatiques configurés
- [ ] Monitoring actif (Netdata ou autre)

---

## 🚨 Dépannage Courant

### Problème: "Connection refused"

```bash
# Vérifier que Docker tourne
ssh deploy@IP "docker ps"

# Redémarrer services
kamal app restart
```

### Problème: "Database connection failed"

```bash
# Vérifier que PostgreSQL est up
kamal accessory logs db

# Recréer database
kamal accessory reboot db
kamal app exec "bin/rails db:prepare"
```

### Problème: "SSL certificate error"

```bash
# Vérifier Traefik
kamal traefik logs

# Forcer renouvellement SSL
kamal traefik reboot
```

### Problème: "Out of memory"

```bash
# Augmenter swap si nécessaire
ssh root@IP
fallocate -l 2G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile

# Ou upgrader serveur (recommandé)
```

---

## 📞 Support

- Hetzner: https://docs.hetzner.com/
- DigitalOcean: https://www.digitalocean.com/community
- Kamal: https://kamal-deploy.org/
- aa Docs: docs/INFRASTRUCTURE_RECOMMENDATIONS.md

---

## 🎯 Commandes Kamal Utiles

```bash
# Déploiement
kamal deploy                    # Déployer nouvelle version
kamal redeploy                  # Redéployer version actuelle
kamal rollback                  # Revenir version précédente

# Gestion app
kamal app logs                  # Voir logs
kamal app logs -f               # Suivre logs en temps réel
kamal app exec "command"        # Exécuter commande
kamal app exec --interactive "bash"  # Shell interactif
kamal app restart               # Redémarrer app
kamal app stop                  # Arrêter app
kamal app start                 # Démarrer app

# Console Rails
kamal app exec --interactive "bin/rails console"

# Database
kamal app exec "bin/rails db:migrate"
kamal app exec "bin/rails db:seed"
kamal app exec "bin/rails db:reset"

# Accessories (PostgreSQL, Redis)
kamal accessory logs db         # Logs PostgreSQL
kamal accessory logs redis      # Logs Redis
kamal accessory restart db      # Redémarrer PostgreSQL
kamal accessory restart redis   # Redémarrer Redis

# Traefik (Reverse Proxy)
kamal traefik logs              # Logs Traefik
kamal traefik restart           # Redémarrer Traefik

# Monitoring
kamal app details               # Infos détaillées
kamal app version               # Version déployée
docker stats                    # Usage ressources
```

---

**Temps estimé déploiement complet: 30-45 minutes**
