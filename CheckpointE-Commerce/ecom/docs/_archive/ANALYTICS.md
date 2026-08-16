# 📊 Analytics - Documentation

La documentation complète du système d'analytics se trouve dans:

**📖 [app/services/analytics/README.md](app/services/analytics/README.md)**

## 🚀 Installation Rapide

```bash
# 1. Installer les gems
bundle install

# 2. Exécuter les migrations
rails db:migrate

# 3. (Optionnel) Configurer les variables d'environnement
cp env.example .env
# Éditez .env si nécessaire

# 4. Redémarrer le serveur
rails restart

# 5. Accéder à l'interface admin
# http://localhost:3000/admin/analytics
```

## 📝 Configuration

**Par défaut (sans configuration):**
- ✅ **AHOY** - Analytics en base de données (activé)
- ❌ **AMPLITUDE** - Désactivé
- ❌ **GOOGLE ANALYTICS** - Désactivé

**Pour activer Amplitude:**

```bash
# .env
AMPLITUDE_ENABLED=true
AMPLITUDE_API_KEY=votre_cle_api_ici
```

## 📖 Documentation Complète

Voir: [app/services/analytics/README.md](app/services/analytics/README.md)

**Contenu:**
- Installation détaillée
- Configuration
- Utilisation (exemples de code)
- Événements disponibles
- Interface admin
- Tracking multi-utilisateurs (Client/Vendor/Employee)
- Amplitude (optionnel)
- Dépannage

---

**Version:** 2.1.0  
**Status:** ✅ Production Ready

