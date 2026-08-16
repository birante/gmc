# Guide PayDunya - Paiement Avec Redirection (PAR)

Ce guide explique comment gérer le mode de paiement par redirection (PAR) avec PayDunya, avec des exemples pratiques utilisant curl et l'intégration dans votre application.

## 🔗 Endpoint API TEST

**URL**: `https://app.paydunya.com/sandbox-api/v1/checkout-invoice/create`  
**Méthode**: `POST`  
**Type**: Paiement Avec Redirection (PAR)

---

## 📋 Exemple de requête curl

```bash
curl -H "Content-Type: application/json" \
-H "PAYDUNYA-MASTER-KEY: wQzk9ZwR-Qq9m-0hD0-zpud-je5coGC3FHKW" \
-H "PAYDUNYA-PRIVATE-KEY: test_private_rMIdJM3PLLhLjyArx9tF3VURAF5" \
-H "PAYDUNYA-TOKEN: IivOiOxGJuWhc5znlIiK" \
-X POST -d '{"invoice": {"total_amount": 5000, "description": "Chaussure VANS dernier modèle"},"store": {"name": "Magasin le Choco"}}' \
"https://app.paydunya.com/sandbox-api/v1/checkout-invoice/create"
```

### Réponse attendue

```json
{
    "response_code": "00",
    "response_text": "https://app.paydunya.com/sandbox-checkout/invoice/test_RHICF0HboN",
    "description": "Checkout Invoice Created",
    "token": "test_RHICF0HboN"
}
```

---

## 🔧 Configuration de vos clés API

Dans votre fichier `.env`, configurez les clés API PayDunya :

```bash
# Mode test ou live
PAYDUNYA_MODE=test

# Clés API PayDunya (TEST)
PAYDUNYA_MASTER_KEY=wQzk9ZwR-Qq9m-0hD0-zpud-je5coGC3FHKW
PAYDUNYA_PUBLIC_KEY=test_public_XXXXXX
PAYDUNYA_PRIVATE_KEY=test_private_rMIdJM3PLLhLjyArx9tF3VURAF5
PAYDUNYA_TOKEN=IivOiOxGJuWhc5znlIiK

# Informations de votre boutique
PAYDUNYA_STORE_NAME=aaApps
PAYDUNYA_STORE_TAGLINE=Votre marketplace en ligne
PAYDUNYA_STORE_PHONE=+221XXXXXXXXX
PAYDUNYA_STORE_ADDRESS=Dakar, Sénégal
PAYDUNYA_STORE_URL=https://votre-domaine.com
PAYDUNYA_STORE_LOGO=https://votre-domaine.com/logo.png
```

---

## 🚀 Flux de paiement PAR (Paiement Avec Redirection)

### 1. **Création de la commande**

Le client valide sa commande sur votre site :

```ruby
# Dans votre OrdersController
def create
  @order = current_user.orders.create!(order_params)
  @payment = @order.payments.create!(
    amount: @order.total_amount,
    payment_method: PaymentMethod.find_by(provider: 'paydunya'),
    status: :pending
  )
  
  # Initialiser le paiement PayDunya
  service = PaymentServices::PaydunyaHttpService.new(
    payment: @payment,
    order: @order,
    user: current_user
  )
  
  result = service.create_checkout_invoice
  
  if result.success?
    # Rediriger vers PayDunya
    redirect_to result.redirect_url, allow_other_host: true
  else
    flash[:error] = result.errors.join(", ")
    render :checkout
  end
end
```

### 2. **Redirection vers PayDunya**

Le client est automatiquement redirigé vers l'URL de paiement PayDunya :
```
https://app.paydunya.com/sandbox-checkout/invoice/test_RHICF0HboN
```

Sur cette page, le client peut :
- Payer par Mobile Money (Wave, Orange Money, Free Money)
- Payer par carte bancaire (Visa, Mastercard)

### 3. **Retour après paiement**

Après le paiement, PayDunya redirige le client vers votre URL de retour :

#### En cas de succès
```
https://votre-domaine.com/paydunya/success?token=test_RHICF0HboN
```

#### En cas d'annulation
```
https://votre-domaine.com/paydunya/cancel?token=test_RHICF0HboN
```

### 4. **Vérification du paiement**

Votre contrôleur `PaydunyaCallbacksController` vérifie le statut :

```ruby
# app/controllers/paydunya_callbacks_controller.rb
def success
  token = params[:token]
  
  # Trouver le paiement par token
  payment = Payment.find_by(paydunya_token: token)
  
  if payment
    # Vérifier le statut auprès de PayDunya
    service = PaymentServices::PaydunyaService.new(
      payment: payment,
      order: payment.order,
      user: payment.order.user
    )
    
    result = service.check_payment_status
    
    if result.success? && payment.completed?
      redirect_to client_order_path(payment.order), 
                  notice: "✅ Paiement confirmé avec succès !"
    else
      redirect_to client_order_path(payment.order), 
                  alert: "⚠️ Paiement en cours de vérification"
    end
  else
    redirect_to root_path, alert: "❌ Transaction introuvable"
  end
end
```

---

## 📝 Payload complet de la requête

Votre application envoie automatiquement un payload complet à PayDunya :

```json
{
  "invoice": {
    "items": {
      "item_0": {
        "name": "Chaussure VANS",
        "quantity": 1,
        "unit_price": "45000",
        "total_price": "45000",
        "description": "Chaussure VANS dernier modèle"
      },
      "item_1": {
        "name": "T-shirt Nike",
        "quantity": 2,
        "unit_price": "15000",
        "total_price": "30000",
        "description": "T-shirt Nike taille M"
      }
    },
    "taxes": {
      "tax_0": {
        "name": "Frais de livraison",
        "amount": 2500
      }
    },
    "customer": {
      "name": "Jean Dupont",
      "email": "jean.dupont@example.com",
      "phone": "+221771234567"
    },
    "total_amount": 77500,
    "description": "Commande #123"
  },
  "store": {
    "name": "aaApps",
    "tagline": "Votre marketplace en ligne",
    "postal_address": "Dakar, Sénégal",
    "phone": "+221338201234",
    "logo_url": "https://aaapps.com/logo.png",
    "website_url": "https://aaapps.com"
  },
  "custom_data": {
    "order_id": 123,
    "user_id": 45,
    "payment_id": 678
  },
  "actions": {
    "cancel_url": "https://aaapps.com/paydunya/cancel",
    "return_url": "https://aaapps.com/paydunya/success",
    "callback_url": "https://aaapps.com/paydunya/ipn"
  }
}
```

---

## 🧪 Tester avec curl en local

### 1. Créer une facture de test

```bash
curl -H "Content-Type: application/json" \
-H "PAYDUNYA-MASTER-KEY: wQzk9ZwR-Qq9m-0hD0-zpud-je5coGC3FHKW" \
-H "PAYDUNYA-PRIVATE-KEY: test_private_rMIdJM3PLLhLjyArx9tF3VURAF5" \
-H "PAYDUNYA-TOKEN: IivOiOxGJuWhc5znlIiK" \
-X POST -d '{
  "invoice": {
    "total_amount": 10000,
    "description": "Test de paiement"
  },
  "store": {
    "name": "aaApps Test"
  }
}' \
"https://app.paydunya.com/sandbox-api/v1/checkout-invoice/create"
```

### 2. Extraire le token et l'URL

Réponse :
```json
{
    "response_code": "00",
    "response_text": "https://app.paydunya.com/sandbox-checkout/invoice/test_ABC123",
    "description": "Checkout Invoice Created",
    "token": "test_ABC123"
}
```

### 3. Ouvrir l'URL dans le navigateur

Ouvrez l'URL retournée dans `response_text` pour effectuer le paiement test.

---

## 🔍 Vérifier le statut d'un paiement

Une fois le token obtenu, vous pouvez vérifier le statut :

```bash
curl -H "Content-Type: application/json" \
-H "PAYDUNYA-MASTER-KEY: wQzk9ZwR-Qq9m-0hD0-zpud-je5coGC3FHKW" \
-H "PAYDUNYA-PRIVATE-KEY: test_private_rMIdJM3PLLhLjyArx9tF3VURAF5" \
-H "PAYDUNYA-TOKEN: IivOiOxGJuWhc5znlIiK" \
-X GET \
"https://app.paydunya.com/sandbox-api/v1/checkout-invoice/confirm/test_ABC123"
```

Réponse si paiement réussi :
```json
{
    "response_code": "00",
    "status": "completed",
    "customer": {
        "name": "Client Test",
        "phone": "+221771234567",
        "email": "test@example.com"
    },
    "receipt_url": "https://app.paydunya.com/receipt/test_ABC123"
}
```

---

## 📊 Diagramme du flux PAR

```
┌─────────────┐
│   Client    │
└──────┬──────┘
       │ 1. Valide commande
       ▼
┌─────────────────────┐
│  Votre Application  │
│  (OrdersController) │
└──────┬──────────────┘
       │ 2. Crée invoice PayDunya
       ▼
┌─────────────────────┐
│   PayDunya API      │
│   (POST /create)    │
└──────┬──────────────┘
       │ 3. Retourne token + URL
       ▼
┌─────────────────────┐
│  Votre Application  │
└──────┬──────────────┘
       │ 4. Redirect client
       ▼
┌─────────────────────┐
│  Page PayDunya      │
│  (Paiement)         │
└──────┬──────────────┘
       │ 5. Client paie
       ▼
┌─────────────────────┐
│  PayDunya           │
└──────┬──────────────┘
       │ 6. Redirect client
       ▼
┌─────────────────────┐
│  Votre Application  │
│  (/paydunya/success)│
└──────┬──────────────┘
       │ 7. Vérifie statut
       ▼
┌─────────────────────┐
│  Confirmation       │
│  Commande validée   │
└─────────────────────┘
```

---

## 🛠️ Codes d'erreur courants

| Code | Signification | Solution |
|------|---------------|----------|
| `1001` | Invalid Masterkey | Vérifier `PAYDUNYA_MASTER_KEY` dans `.env` |
| `1002` | Invalid Private Key | Vérifier `PAYDUNYA_PRIVATE_KEY` dans `.env` |
| `1003` | Invalid Token | Vérifier `PAYDUNYA_TOKEN` dans `.env` |
| `1004` | Invalid amount | Le montant doit être > 0 |
| `1005` | Missing required field | Vérifier le payload JSON |

---

## 🔐 Sécurité

### ⚠️ Points importants

1. **Ne jamais exposer les clés API côté client** : Les requêtes à PayDunya doivent toujours être faites côté serveur (Ruby on Rails).

2. **Toujours vérifier le statut côté serveur** : Ne jamais faire confiance aux paramètres d'URL uniquement.

3. **Utiliser les webhooks IPN** : Configurez l'URL IPN pour recevoir les notifications asynchrones :
   ```
   https://votre-domaine.com/paydunya/ipn
   ```

4. **HTTPS obligatoire en production** : PayDunya exige HTTPS pour les callbacks.

5. **Valider les montants** : Toujours vérifier que le montant payé correspond au montant de la commande.

---

## 📞 Support et documentation

- **Documentation officielle** : [https://paydunya.com/developers](https://paydunya.com/developers)
- **Dashboard PayDunya** : [https://app.paydunya.com](https://app.paydunya.com)
- **Support** : support@paydunya.com

---

## ✅ Checklist d'intégration

- [ ] Clés API configurées dans `.env`
- [ ] Service `PaydunyaHttpService` testé
- [ ] Routes de callback définies (`/paydunya/success`, `/paydunya/cancel`, `/paydunya/ipn`)
- [ ] URLs de callback configurées dans le payload
- [ ] Test en mode sandbox réussi
- [ ] Vérification du statut implémentée
- [ ] Gestion des erreurs en place
- [ ] Logs configurés pour le débogage
- [ ] HTTPS configuré en production
- [ ] Webhook IPN testé

---

## 🎯 Prochaines étapes

Une fois le mode PAR fonctionnel, vous pouvez :

1. Implémenter le mode PSR (Paiement Sans Redirection) pour une meilleure UX
2. Ajouter des notifications email après paiement
3. Créer un dashboard de suivi des paiements
4. Implémenter la gestion des remboursements
5. Ajouter des statistiques de conversion

---

**Dernière mise à jour** : Décembre 2024
