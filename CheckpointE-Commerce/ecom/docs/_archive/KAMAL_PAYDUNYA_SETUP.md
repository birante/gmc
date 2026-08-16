# 🔐 Configuration PayDunya avec Kamal

Ce document explique comment configurer les variables d'environnement PayDunya avec Kamal et les secrets.

## 📋 Variables PayDunya

**Toutes les variables PayDunya sont gérées comme secrets** pour centraliser la configuration et faciliter la gestion des environnements.

### Secrets PayDunya (toutes dans GitHub Secrets)

- `PAYDUNYA_MASTER_KEY` - Clé principale PayDunya (sensible)
- `PAYDUNYA_PRIVATE_KEY` - Clé privée PayDunya (sensible)
- `PAYDUNYA_TOKEN` - Token d'authentification PayDunya (sensible)
- `PAYDUNYA_PUBLIC_KEY` - Clé publique PayDunya
- `PAYDUNYA_MODE` - Mode : `"test"` ou `"live"`
- `PAYDUNYA_STORE_NAME` - Nom de votre boutique
- `PAYDUNYA_STORE_TAGLINE` - Slogan de votre boutique
- `PAYDUNYA_STORE_PHONE` - Téléphone de contact
- `PAYDUNYA_STORE_ADDRESS` - Adresse de votre boutique
- `PAYDUNYA_STORE_URL` - URL de votre site (pour les callbacks)
- `PAYDUNYA_STORE_LOGO` - URL du logo (optionnel)

## 🔧 Configuration locale

### 1. Fichier `.kamal/secrets`

Les secrets sont référencés dans `.kamal/secrets` :

```bash
# PayDunya API credentials (secrets - sensitive)
PAYDUNYA_MASTER_KEY=$PAYDUNYA_MASTER_KEY
PAYDUNYA_PRIVATE_KEY=$PAYDUNYA_PRIVATE_KEY
PAYDUNYA_TOKEN=$PAYDUNYA_TOKEN
```

Ces variables doivent être définies dans votre environnement local avant d'exécuter `kamal deploy`.

### 2. Fichier `config/deploy.yml`

**Toutes les variables PayDunya sont déclarées dans la section `env.secret`** :

```yaml
env:
  secret:
    - PAYDUNYA_MASTER_KEY
    - PAYDUNYA_PRIVATE_KEY
    - PAYDUNYA_TOKEN
    - PAYDUNYA_PUBLIC_KEY
    - PAYDUNYA_MODE
    - PAYDUNYA_STORE_NAME
    - PAYDUNYA_STORE_TAGLINE
    - PAYDUNYA_STORE_PHONE
    - PAYDUNYA_STORE_ADDRESS
    - PAYDUNYA_STORE_URL
    - PAYDUNYA_STORE_LOGO
```

Les valeurs sont définies dans `.kamal/secrets` et injectées via les variables d'environnement.

## 🚀 Configuration GitHub Actions

### 1. Ajouter les secrets dans GitHub

Allez dans **Settings > Secrets and variables > Actions** et ajoutez **toutes** les variables PayDunya :

**Secrets sensibles (obligatoires)** :
- `PAYDUNYA_MASTER_KEY` - Votre clé principale PayDunya
- `PAYDUNYA_PRIVATE_KEY` - Votre clé privée PayDunya
- `PAYDUNYA_TOKEN` - Votre token PayDunya

**Configuration publique (recommandées)** :
- `PAYDUNYA_PUBLIC_KEY` - Votre clé publique PayDunya
- `PAYDUNYA_MODE` - `"live"` pour production, `"test"` pour staging
- `PAYDUNYA_STORE_NAME` - Nom de votre boutique
- `PAYDUNYA_STORE_TAGLINE` - Slogan de votre boutique
- `PAYDUNYA_STORE_PHONE` - Téléphone de contact
- `PAYDUNYA_STORE_ADDRESS` - Adresse de votre boutique
- `PAYDUNYA_STORE_URL` - URL de votre site (ex: `https://aa.okemamy.com`)
- `PAYDUNYA_STORE_LOGO` - URL du logo (optionnel)

**Pour staging** (optionnel, utilise les valeurs de production si non définis) :
- `PAYDUNYA_MASTER_KEY_STAGING`
- `PAYDUNYA_PRIVATE_KEY_STAGING`
- `PAYDUNYA_TOKEN_STAGING`
- `PAYDUNYA_PUBLIC_KEY_STAGING`
- `PAYDUNYA_MODE_STAGING` (généralement `"test"`)
- `PAYDUNYA_STORE_NAME_STAGING`
- `PAYDUNYA_STORE_URL_STAGING` (ex: `https://staging.aa.okemamy.com`)
- etc.

### 2. Workflow GitHub Actions

Les secrets sont automatiquement injectés dans le workflow via :

```yaml
env:
  PAYDUNYA_MASTER_KEY: ${{ secrets.PAYDUNYA_MASTER_KEY }}
  PAYDUNYA_PRIVATE_KEY: ${{ secrets.PAYDUNYA_PRIVATE_KEY }}
  PAYDUNYA_TOKEN: ${{ secrets.PAYDUNYA_TOKEN }}
```

## 📝 Mise à jour des valeurs

**Toutes les valeurs sont gérées via les secrets**, pas dans les fichiers de configuration.

### Pour la production

Mettez à jour les secrets dans **GitHub Secrets** :
- `PAYDUNYA_MODE` = `"live"`
- `PAYDUNYA_STORE_URL` = `"https://aa.okemamy.com"`
- `PAYDUNYA_STORE_NAME` = `"aaApps"`
- etc.

### Pour le staging

Mettez à jour les secrets dans **GitHub Secrets** avec le suffixe `_STAGING` :
- `PAYDUNYA_MODE_STAGING` = `"test"`
- `PAYDUNYA_STORE_URL_STAGING` = `"https://staging.aa.okemamy.com"`
- etc.

Si les secrets `_STAGING` n'existent pas, les valeurs de production seront utilisées.

## 🔄 Déploiement

### Déploiement local

1. **Définir les variables d'environnement** :
   ```bash
   export PAYDUNYA_MASTER_KEY="votre_cle"
   export PAYDUNYA_PRIVATE_KEY="votre_cle_privee"
   export PAYDUNYA_TOKEN="votre_token"
   ```

2. **Déployer** :
   ```bash
   bin/kamal deploy
   ```

### Déploiement via GitHub Actions

Les secrets sont automatiquement injectés lors du déploiement. Assurez-vous simplement que les secrets sont configurés dans GitHub.

## ✅ Vérification

Après le déploiement, vérifiez que les variables sont bien chargées :

```bash
bin/kamal app exec "rails runner \"puts ENV['PAYDUNYA_MASTER_KEY'].present? ? '✅ PayDunya configuré' : '❌ PayDunya non configuré'\""
```

## 🔒 Sécurité

- ✅ **Ne jamais** commiter les clés API dans le code
- ✅ **Toujours** utiliser les secrets pour les clés sensibles
- ✅ **Vérifier** que `.kamal/secrets` est dans `.gitignore`
- ✅ **Utiliser** des clés différentes pour staging et production si possible

## 📚 Références

- [Documentation Kamal - Secrets](https://kamal-deploy.org/docs/secrets)
- [Documentation PayDunya](https://paydunya.com/developers)
