# Configuration PayDunya

## Obtenir vos clés API PayDunya

Pour que le paiement PayDunya fonctionne correctement, vous devez obtenir de vraies clés API depuis votre compte PayDunya.

### Étape 1 : Créer un compte PayDunya

1. Visitez [https://paydunya.com](https://paydunya.com)
2. Cliquez sur "S'inscrire" ou "Sign Up"
3. Remplissez le formulaire d'inscription avec vos informations
4. Vérifiez votre email et activez votre compte

### Étape 2 : Accéder au Dashboard

1. Connectez-vous à votre compte PayDunya
2. Accédez à votre Dashboard
3. Naviguez vers la section "API" ou "Développeurs"

### Étape 3 : Générer vos clés API

Dans la section API/Développeurs, vous trouverez :

- **Master Key** (Clé Principale)
- **Public Key** (Clé Publique)  
- **Private Key** (Clé Privée)
- **Token**

PayDunya fournit généralement deux environnements :
- **Test** : pour le développement et les tests
- **Live** : pour la production

### Étape 4 : Configurer votre application

1. Ouvrez le fichier `.env` à la racine du projet
2. Remplacez les valeurs par défaut par vos vraies clés :

```bash
# Clés API PayDunya (obtenues depuis votre dashboard PayDunya)
PAYDUNYA_MASTER_KEY=votre_vraie_master_key_ici
PAYDUNYA_PUBLIC_KEY=votre_vraie_public_key_ici
PAYDUNYA_PRIVATE_KEY=votre_vraie_private_key_ici
PAYDUNYA_TOKEN=votre_vrai_token_ici

# Mode: "test" pour le développement, "live" pour la production
PAYDUNYA_MODE=test
```

3. **IMPORTANT** : Redémarrez votre serveur Rails après avoir modifié le `.env`

```bash
# Arrêtez le serveur (Ctrl+C) puis relancez
rails s
```

### Étape 5 : Tester le paiement

1. Accédez au processus de commande sur votre application
2. Sélectionnez "PayDunya" comme méthode de paiement
3. Cliquez sur "Valider et payer"
4. Vous devriez être redirigé vers la page de paiement PayDunya

## Informations de la boutique

Vous pouvez personnaliser les informations affichées sur la page de paiement PayDunya en modifiant ces variables dans `.env` :

```bash
PAYDUNYA_STORE_NAME=aaApps
PAYDUNYA_STORE_TAGLINE=Votre marketplace en ligne
PAYDUNYA_STORE_PHONE=+221776857298
PAYDUNYA_STORE_ADDRESS=Dakar, Sénégal
PAYDUNYA_STORE_URL=http://localhost:3000
PAYDUNYA_STORE_LOGO=https://votresite.com/logo.png
```

## Environnement de test vs Production

### Mode Test
- Utilisez les clés de test (préfixées par `test_`)
- Aucun argent réel n'est débité
- Parfait pour le développement

```bash
PAYDUNYA_MODE=test
```

### Mode Production (Live)
- Utilisez les clés de production
- Les vrais paiements sont traités
- À utiliser uniquement après avoir testé complètement

```bash
PAYDUNYA_MODE=live
```

## Dépannage

### Erreur "Invalid Masterkey Specified"

Cette erreur signifie que les clés API ne sont pas valides. Vérifiez :

1. ✅ Vous avez bien copié les clés complètes sans espaces
2. ✅ Vous utilisez les clés du bon environnement (test ou live)
3. ✅ Votre compte PayDunya est activé
4. ✅ Vous avez redémarré le serveur Rails après modification du `.env`

### Le paiement ne se lance pas

1. Vérifiez les logs Rails : `tail -f log/development.log`
2. Recherchez les messages d'erreur contenant `[PayDunya]`
3. Assurez-vous que votre compte PayDunya est bien configuré

## URLs de callback

Les URLs de callback (cancel_url et return_url) sont configurées automatiquement par l'application. Vous n'avez pas besoin de les modifier dans le fichier `.env`.

## Support

Pour plus d'informations :
- Documentation PayDunya : [https://paydunya.com/developers](https://paydunya.com/developers)
- Documentation Ruby SDK : [https://github.com/paydunya/paydunya-ruby](https://github.com/paydunya/paydunya-ruby)
