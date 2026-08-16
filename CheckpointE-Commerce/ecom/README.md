# aa

Plateforme e-commerce multi-tenant (Rails 8, Ruby 3.4.7, PostgreSQL 17) avec trois espaces : Clients, Vendors, Employees. Stack principale :
- Rails 8.0.3 / Ruby 3.4.7 (Mise)
- PostgreSQL 17 + Solid Cable/Cache/Queue
- Tailwind CSS v4 (tailwindcss-rails + Propshaft)
- Hotwire (Turbo + Stimulus)
- ActiveAdmin (FR/EN)
- Ahoy + Chartkick pour analytics

## Démarrage local

```bash
./start_local.sh           # Foreman (Rails + Tailwind watch)
# ou
bundle exec rails server   # Port 3000
bundle exec rails tailwindcss:watch
```

### Base de données
```bash
bundle exec rails db:create db:migrate db:seed
# reset complet
bundle exec rails db:reset
```

### Tests & qualité
```bash
bundle exec rails test          # suite Minitest
bundle exec rubocop             # style
bundle exec brakeman            # sécurité
./script/test_performance.sh    # vérifs perfs (cache, Ahoy, recommandations)
```

### Déploiement Kamal (production & preprod)
Déploiement via Kamal (Docker), avec un fichier de config par environnement.

```bash
# Production (config/deploy.yml)
bundle exec kamal setup -c config/deploy.yml    # premier déploiement uniquement
bundle exec kamal deploy -c config/deploy.yml
```

```bash
# Preprod (attention: le fichier contient un espace dans son nom)
bundle exec kamal setup -c "config/deploy.preprod.yml"   # premier déploiement uniquement
bundle exec kamal deploy -c "config/deploy.preprod.yml"
```

Notes :
- Secrets production : `.kamal/secrets`
- Secrets preprod : `.kamal/secrets.preprod`
- L'environnement Rails est actuellement fixé à `production` dans les Dockerfiles (`Dockerfile` et `Dockerfile.preprod`).

### Exploitation Kamal (logs, console, shell)

```bash
# Production
bundle exec kamal app logs -f -c config/deploy.yml
bundle exec kamal app exec --interactive --reuse "bin/rails console" -c config/deploy.yml
bundle exec kamal app exec --interactive --reuse "bash" -c config/deploy.yml
bundle exec kamal app exec --interactive --reuse "bin/rails dbconsole" -c config/deploy.yml
bundle exec kamal details -c config/deploy.yml
bundle exec kamal rollback -c config/deploy.yml
```

```bash
# Preprod
bundle exec kamal app logs -f -c "config/deploy. preprod.yml"
bundle exec kamal app exec --interactive --reuse "bin/rails console" -c "config/deploy.preprod.yml"
bundle exec kamal app exec --interactive --reuse "bash" -c "config/deploy.preprod.yml"
bundle exec kamal app exec --interactive --reuse "bin/rails dbconsole" -c "config/deploy.preprod.yml"
bundle exec kamal details -c "config/deploy.preprod.yml"
bundle exec kamal rollback -c "config/deploy.preprod.yml"
```

Astuce :
- Tu peux aussi utiliser les alias définis dans `deploy.yml` (`logs`, `console`, `shell`, `dbc`), en gardant `-c ...` :
  - `bundle exec kamal logs -c config/deploy.yml`
  - `bundle exec kamal console -c "config/deploy.preprod.yml"`

### Configuration PayDunya
- Clés/API et Store via credentials ou ENV :
	- `paydunya.master_key`, `public_key`, `private_key`, `token`, `mode`
	- `paydunya.store_name`, `store_tagline`, `store_phone`, `store_address`, `store_url`, `store_logo_url`
- Équivalents ENV : `PAYDUNYA_MASTER_KEY`, `PAYDUNYA_PUBLIC_KEY`, `PAYDUNYA_PRIVATE_KEY`, `PAYDUNYA_TOKEN`, `PAYDUNYA_MODE`, `PAYDUNYA_STORE_*`, `APP_URL`.
- Tout est centralisé dans `config/initializers/paydunya.rb` via `PaydunyaConfig.setup!`.

## Points d’architecture clés
- Auth multi-profils : User (client), Vendor, Employee avec sessions polymorphes.
- Contexte boutique : toujours filtrer par shop (VendorShopContext / EmployeeShopContext).
- Analytics : Trackable + Ahoy (`analytics.track_event`), docs détaillées dans `docs/analytics/`.
- I18n : défaut fr, en support, scope `(:locale)` dans les routes.
- Téléphone : `PhoneValidationService` (phonelib) avec normalisation.
- Logging : conventions emoji (👤 User, 🏪 Vendor, 👷 Employee, 🛒 Cart, 📦 Order, 📝 Shop).

## Arborescence utile
- Routes : `config/routes.rb`
- Contrôleurs : `app/controllers/{client,vendors,employees}/`
- Modèles : `app/models/`
- Services : `app/services/`
- Admin : `app/admin/`
- Docs : `docs/` (toutes les fiches techniques et guides)

## Docs à lire en priorité
- `docs/README.md` (index)
- `docs/PERFORMANCE_OPTIMIZATION.md`
- `docs/setup/I18N_VERIFICATION.md`
- `docs/setup/ACTIVE_ADMIN_I18N.md`
- `docs/rules/RULES_AND_CONVENTIONS.md`
- `docs/performance/` (checklists et scripts)

## Contribuer
1. Créer une branche `feature/<nom>` depuis `develop` (Gitmoji + Gitflow).
2. Ajouter tests et traductions pour toute surface user-facing.
3. Exécuter `bundle exec rails test && bundle exec rubocop && bundle exec brakeman` avant PR.
4. Mettre à jour la doc dans `docs/` si nécessaire.
5. Vérifier la règle Markdown : `bundle exec rake markdown:enforce` (tous les .md doivent vivre sous `docs/`, hors README root/.github).

## Support
- Local : voir `LOCAL_DEV.md` (si présent) ou `docs/setup/`.
- Analytics : `docs/services/analytics/README.md`.
- Tests perf : `./script/test_performance.sh` (guide détaillé : `docs/performance/`).


Parfait — d’après tes fichiers, tu dois pointer ces hôtes :

- **Prod** (`config/deploy.yml`)  
  - `sn.aa.com`
  - `www.sn.aa.com`
- **Preprod** (`config/deploy.preprod.yml`)  
  - `preprod.aa.com`
  - `www.preprod.aa.com`

## Configuration DNS GoDaddy

Dans la zone DNS de `aa.com`, crée/modifie :

### Production (IP `0.0.0.0`)
- `A` → Host `sn` → `0.0.0.0`
- `CNAME` → Host `www.sn` → `sn.aa.com`  
  (ou un `A` direct vers `0.0.0.0`)

### Preprod (IP `0.0.0.0`)
- `A` → Host `preprod` → `0.0.0.0`
- `CNAME` → Host `www.preprod` → `preprod.aa.com`  
  (ou un `A` direct vers `0.0.0.0`)

## Points importants

- Supprime les enregistrements en conflit (anciens `A/CNAME` sur ces mêmes hosts).
- TTL: `600` (10 min) pour propagation rapide.
- Vérifie que les ports **80 et 443** sont ouverts sur tes 2 serveurs (indispensable pour Let's Encrypt).
- Comme tu as `proxy.ssl: true` dans les deux configs, Kamal/Traefik gère le certificat automatiquement une fois DNS propagé.

## Vérifier la propagation

```bash
dig +short sn.aa.com
dig +short www.sn.aa.com
dig +short preprod.aa.com
dig +short www.preprod.aa.com
```

Tu dois voir les bonnes IPs.

## Ensuite déployer

```bash
# prod
bundle exec kamal deploy -c config/deploy.yml

# preprod
bundle exec kamal deploy -c config/deploy.preprod.yml
```

Si tu veux, je peux aussi te donner une checklist “si le SSL ne sort pas” (erreurs courantes Traefik/ACME).