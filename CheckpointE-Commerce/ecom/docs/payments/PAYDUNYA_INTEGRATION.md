# Intégration PayDunya

Cette documentation décrit l'intégration de l'API PayDunya pour le traitement des paiements dans l'application aaApps.

## Vue d'ensemble

PayDunya est intégré avec support pour deux types de paiements :

1. **PAR (Paiement Avec Redirection)** : Le client est redirigé vers la page de paiement PayDunya
2. **PSR (Paiement Sans Redirection)** : Le client reçoit un code de confirmation par SMS/email et le saisit dans l'application

## Configuration

### 1. Variables d'environnement

Ajoutez les variables suivantes dans votre fichier `.env` :

```bash
# Clés API PayDunya
PAYDUNYA_MASTER_KEY=votre_cle_principale
PAYDUNYA_PUBLIC_KEY=votre_cle_publique
PAYDUNYA_PRIVATE_KEY=votre_cle_privee
PAYDUNYA_TOKEN=votre_token

# Mode: "test" ou "live"
PAYDUNYA_MODE=test

# Informations de votre entreprise
PAYDUNYA_STORE_NAME=aaApps
PAYDUNYA_STORE_TAGLINE=Votre marketplace en ligne
PAYDUNYA_STORE_PHONE=+221XXXXXXXXX
PAYDUNYA_STORE_ADDRESS=Adresse de votre entreprise
PAYDUNYA_STORE_URL=https://aaapps.com
PAYDUNYA_STORE_LOGO=https://aaapps.com/logo.png

# URLs de callback (optionnel - définies automatiquement)
PAYDUNYA_CANCEL_URL=
PAYDUNYA_RETURN_URL=
```

### 2. Configuration des méthodes de paiement

Dans l'interface d'administration ActiveAdmin, créez une méthode de paiement avec les paramètres suivants :

- **Code** : `paydunya`
- **Nom** : `PayDunya`
- **Provider** : `paydunya`
- **Type** : `online`
- **Actif** : `true`

## Fichiers créés

### Services

- **`app/services/payment_services/paydunya_service.rb`** : Service principal pour gérer les paiements PayDunya
  - `create_checkout_invoice` : Crée une facture PAR
  - `create_onsite_invoice` : Crée une facture PSR
  - `charge_onsite_invoice` : Charge un paiement PSR avec le code de confirmation
  - `check_payment_status` : Vérifie le statut d'un paiement

### Contrôleurs

- **`app/controllers/paydunya_callbacks_controller.rb`** : Gère les callbacks PayDunya
  - `success` : Callback après paiement réussi (PAR)
  - `cancel` : Callback après annulation de paiement (PAR)
  - `ipn` : Webhook pour les notifications instantanées (IPN)
  - `charge` : Endpoint pour charger un paiement PSR

### Configuration

- **`config/initializers/paydunya.rb`** : Initializer pour configurer l'API PayDunya

### Migrations

- **`db/migrate/XXXXXX_add_paydunya_fields_to_payments.rb`** : Ajoute les colonnes PayDunya à la table `payments`
  - `paydunya_token` : Token unique de la transaction PayDunya
  - `paydunya_invoice_url` : URL de la facture/reçu PayDunya
  - `payment_type` : Type de paiement (PAR ou PSR)
  - `provider_response` : Réponse JSON du provider

## Routes

Les routes suivantes ont été ajoutées :

```ruby
GET  /paydunya/success  -> paydunya_callbacks#success
GET  /paydunya/cancel   -> paydunya_callbacks#cancel
POST /paydunya/ipn      -> paydunya_callbacks#ipn
POST /paydunya/charge   -> paydunya_callbacks#charge
```

## Flux de paiement

### Paiement Avec Redirection (PAR)

1. Le client valide sa commande
2. Le système crée une facture PayDunya
3. Le client est redirigé vers la page de paiement PayDunya
4. Après paiement, le client est redirigé vers `/paydunya/success?token=XXX`
5. Le système vérifie le statut du paiement et met à jour la commande

### Paiement Sans Redirection (PSR)

1. Le client valide sa commande avec son email/téléphone
2. Le système crée une facture PSR
3. Le client reçoit un code de confirmation par SMS/email
4. Le client saisit le code de confirmation dans l'application
5. L'application appelle `/paydunya/charge` avec le token et le code
6. Le paiement est confirmé et la commande est mise à jour

## Utilisation

### Dans le formulaire de commande

Pour utiliser PayDunya, ajoutez un champ caché pour spécifier le type de paiement :

```html
<!-- Pour PAR (par défaut) -->
<input type="hidden" name="paydunya_payment_type" value="PAR">

<!-- Pour PSR -->
<input type="hidden" name="paydunya_payment_type" value="PSR">
```

### Charger un paiement PSR (via AJAX)

```javascript
// Exemple d'appel AJAX pour charger un paiement PSR
fetch('/paydunya/charge', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
  },
  body: JSON.stringify({
    token: 'TOKEN_PAYDUNYA',
    confirmation_code: '123456'
  })
})
.then(response => response.json())
.then(data => {
  if (data.success) {
    // Rediriger vers la page de commande
    window.location.href = data.order_url;
  } else {
    // Afficher l'erreur
    alert(data.error);
  }
});
```

## Webhook IPN

Pour configurer le webhook IPN dans votre compte PayDunya :

1. Connectez-vous à votre dashboard PayDunya
2. Allez dans les paramètres de votre application
3. Configurez l'URL IPN : `https://votre-domaine.com/paydunya/ipn`

Le système mettra automatiquement à jour le statut des paiements lors de la réception des notifications IPN.

## Tests

### Mode test

En mode test, utilisez les clés de test fournies par PayDunya. Les paiements ne seront pas réellement débités.

### Vérifier l'intégration

1. Créez une commande de test
2. Sélectionnez PayDunya comme méthode de paiement
3. Complétez le processus de paiement
4. Vérifiez que la commande est mise à jour correctement

## Logging

Tous les événements PayDunya sont loggés avec des emojis pour faciliter le débogage :

- 💳 Création de facture
- ✅ Succès
- ❌ Erreur
- ⚠️ Avertissement
- 🔍 Vérification
- 📬 Notification IPN
- 🔄 Redirection

Exemple de log :
```
💳 [PayDunya] Création invoice checkout - order_id: 123, montant: 50000
✅ [PayDunya] Invoice créée - token: abc123, url: https://paydunya.com/...
```

## Support

Pour toute question concernant l'intégration PayDunya :

- Documentation officielle : https://paydunya.com/developers/ruby
- Support PayDunya : support@paydunya.com
- Documentation GitHub : https://github.com/paydunyadev/paydunya-ruby-master

## Sécurité

⚠️ **Important** :

1. Ne jamais commiter les clés API dans le code source
2. Toujours utiliser des variables d'environnement
3. Valider le statut du paiement côté serveur (ne jamais faire confiance aux callbacks clients)
4. Utiliser HTTPS en production
5. Vérifier l'authenticité des notifications IPN

## Prochaines étapes

- [ ] Ajouter des tests unitaires pour le service PayDunya
- [ ] Créer une interface utilisateur pour le paiement PSR
- [ ] Ajouter des notifications email pour les paiements réussis
- [ ] Implémenter la gestion des remboursements
- [ ] Ajouter des statistiques de paiement dans le dashboard
