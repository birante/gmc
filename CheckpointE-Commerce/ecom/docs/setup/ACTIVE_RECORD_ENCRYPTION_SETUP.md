# Configuration du Chiffrement Active Record

## 🔐 Problème Résolu

Lors de l'implémentation du modèle `PendingRegistration`, l'erreur suivante est apparue :

```
Missing Active Record encryption credential: active_record_encryption.primary_key
```

## ✅ Solution Appliquée

### 1. Génération des Clés

```bash
bin/rails db:encryption:init
```

Cette commande génère trois clés nécessaires :
- `primary_key` : Clé principale de chiffrement
- `deterministic_key` : Clé pour le chiffrement déterministe
- `key_derivation_salt` : Salt pour la dérivation de clés

### 2. Configuration des Credentials

Les clés ont été ajoutées aux **credentials de développement** :

**Fichier** : `config/credentials/development.yml.enc`  
**Clé de déchiffrement** : `config/credentials/development.key`

Contenu ajouté :
```yaml
active_record_encryption:
  primary_key: G5A7phii6OLPn1STFlQDbouuLmflkolp
  deterministic_key: zDOXftTfBzpPBwRxtWgvkXA4RAbUusvK
  key_derivation_salt: ljQ9nyDwfhzRuLBhCwnRKrVouQt5muXz
```

### 3. Vérification

```bash
# Vérifier que les clés sont accessibles
rails runner "puts Rails.application.credentials.active_record_encryption.inspect"

# Tester le chiffrement
ruby /tmp/test_registration.rb
```

## 📝 Pour les Autres Environnements

### Production

```bash
# Générer les clés pour production
RAILS_ENV=production bin/rails db:encryption:init

# Éditer les credentials production
EDITOR=vim bin/rails credentials:edit --environment production
```

Ajouter le même bloc `active_record_encryption` avec les clés générées.

### Staging

```bash
# Générer les clés pour staging
RAILS_ENV=staging bin/rails db:encryption:init

# Éditer les credentials staging
EDITOR=vim bin/rails credentials:edit --environment staging
```

## 🔒 Sécurité

### Points Importants

1. **Ne JAMAIS commiter les clés de déchiffrement** (`.key` files)
   - Déjà dans `.gitignore` : `config/credentials/*.key`

2. **Sauvegarder les clés en lieu sûr**
   - Utiliser un gestionnaire de mots de passe d'équipe (1Password, LastPass, etc.)
   - Stocker dans un coffre-fort d'entreprise
   - Documenter dans la documentation privée du projet

3. **Rotation des clés**
   - Prévoir une stratégie de rotation des clés
   - Rails supporte la rotation : https://edgeguides.rubyonrails.org/active_record_encryption.html#rotating-keys

4. **Variables d'environnement (alternative)**
   - Pour les environnements conteneurisés, utiliser des variables :
   ```ruby
   # config/application.rb
   config.active_record.encryption.primary_key = ENV['AR_ENCRYPTION_PRIMARY_KEY']
   config.active_record.encryption.deterministic_key = ENV['AR_ENCRYPTION_DETERMINISTIC_KEY']
   config.active_record.encryption.key_derivation_salt = ENV['AR_ENCRYPTION_KEY_DERIVATION_SALT']
   ```

## 🧪 Tests

Le chiffrement a été testé avec succès :

```bash
ruby /tmp/test_registration.rb
```

Résultat :
```
Test du service Clients::RegistrationService.create
OK Inscription reussie!
Pending ID: 2
Email: testclient@example.com
Phone: 776123456
OTP Code: 4285
Expires at: 2026-01-30 13:33:26 UTC

Test du service Clients::RegistrationService.verify
OK Verification reussie et compte cree!
User ID: 1
Email: testclient@example.com
Verified: false
Test nettoye
```

## 📚 Ressources

- [Rails Encrypted Credentials](https://edgeguides.rubyonrails.org/security.html#custom-credentials)
- [Active Record Encryption](https://edgeguides.rubyonrails.org/active_record_encryption.html)

---

**Date** : 30 janvier 2026  
**Status** : ✅ Configuré et testé
