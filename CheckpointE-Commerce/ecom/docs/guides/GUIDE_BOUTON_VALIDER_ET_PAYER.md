# Guide : Bouton "Valider et Payer" avec Redirection PayDunya

## ✅ Statut de l'intégration

**TOUT EST DÉJÀ EN PLACE ET FONCTIONNEL !** 🎉

Le flux de paiement avec redirection (PAR) est complètement implémenté dans votre application.

---

## 🎯 Ce qui se passe quand on clique sur "Valider et payer"

### Flux complet pas à pas

```
┌─────────────────────────────────────────────────────────────┐
│  1. Client remplit le formulaire de commande                │
│     - Adresse de livraison                                   │
│     - Zone de livraison                                      │
│     - Créneau horaire                                        │
│     - Sélectionne PayDunya comme méthode de paiement         │
│     - Clique sur "Valider et payer"                          │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  2. Client::OrdersController#create                          │
│     └─> Checkout::FinalizeOrderService.call                 │
│         ├─> Crée la commande (Order)                         │
│         ├─> Crée les items de commande (OrderItems)          │
│         ├─> Crée le paiement (Payment)                       │
│         └─> PaymentServices::PaydunyaHttpService             │
│             └─> POST https://app.paydunya.com/.../create     │
│                 Retourne: {                                  │
│                   token: "test_ABC123",                      │
│                   url: "https://paydunya.com/checkout/..."   │
│                 }                                            │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  3. Redirection automatique vers PayDunya                    │
│     redirect_to result.redirect_url, allow_other_host: true  │
│                                                              │
│     Le client voit la page de paiement PayDunya avec:        │
│     ✓ Montant à payer                                        │
│     ✓ Description de la commande                             │
│     ✓ Options: Wave, Orange Money, Free Money, Carte         │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  4. Client effectue le paiement sur PayDunya                 │
│     - Choisit Wave / Orange Money / Free Money / Carte       │
│     - Saisit ses informations de paiement                    │
│     - Valide le paiement                                     │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  5. PayDunya traite le paiement et redirige                  │
│                                                              │
│     Si succès:                                               │
│     → http://localhost:3000/paydunya/success?token=ABC123    │
│                                                              │
│     Si annulation:                                           │
│     → http://localhost:3000/paydunya/cancel?token=ABC123     │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  6. PaydunyaCallbacksController#success                      │
│     ├─> Trouve le Payment par token                          │
│     ├─> PaymentServices::PaydunyaService#check_payment_status│
│     │   └─> GET https://app.paydunya.com/.../confirm/{token} │
│     │       Vérifie le statut réel du paiement               │
│     │                                                         │
│     ├─> Met à jour Payment.status = "completed"              │
│     ├─> Met à jour Order.status = "processing"               │
│     │                                                         │
│     └─> Redirige vers /client/orders/{id}                    │
│         avec message: "Paiement confirmé avec succès!"       │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔍 Code impliqué (déjà en place)

### 1. Contrôleur des commandes
**Fichier**: `app/controllers/client/orders_controller.rb`

```ruby
def create
  # ... préparation ...
  
  service = Checkout::FinalizeOrderService.new(
    user: current_user,
    cart: current_cart,
    params: checkout_params
  )
  
  result = service.call
  
  if result.success?
    # Vérifier si c'est un paiement PayDunya PAR qui nécessite une redirection
    if result.paydunya_redirect_url.present?
      Rails.logger.info("[Client::OrdersController] Redirection vers PayDunya")
      redirect_to result.paydunya_redirect_url, allow_other_host: true
    else
      redirect_to client_dashboard_path, notice: "Paiement confirmé!"
    end
  else
    # Gestion d'erreur
  end
end
```

### 2. Service de finalisation
**Fichier**: `app/services/checkout/finalize_order_service.rb`

```ruby
def process_paydunya_payment
  service = PaymentServices::PaydunyaHttpService.new(
    payment: payment,
    order: order,
    user: user
  )
  
  # Créer l'invoice avec redirection (PAR)
  result = service.create_checkout_invoice
  
  unless result.success?
    raise StandardError, result.errors.join(", ")
  end
  
  # Stocker l'URL de redirection
  @paydunya_redirect_url = result.redirect_url
end
```

### 3. Service HTTP PayDunya
**Fichier**: `app/services/payment_services/paydunya_http_service.rb`

```ruby
def create_checkout_invoice
  response = self.class.post(
    "#{@base_url}/checkout-invoice/create",
    headers: headers,
    body: build_invoice_payload.to_json,
    timeout: 30
  )
  
  if response.success? && response.parsed_response["response_code"] == "00"
    # Retourne l'URL de redirection
    handle_success_response(response.parsed_response)
  end
end
```

### 4. Contrôleur de callback
**Fichier**: `app/controllers/paydunya_callbacks_controller.rb`

```ruby
def success
  token = params[:token]
  payment = Payment.find_by(paydunya_token: token)
  
  if payment
    service = PaymentServices::PaydunyaService.new(
      payment: payment,
      order: payment.order,
      user: payment.order.user
    )
    
    result = service.check_payment_status
    
    if result.success? && payment.completed?
      redirect_to client_order_path(payment.order), 
                  notice: "✅ Paiement confirmé avec succès !"
    end
  end
end
```

---

## 🧪 Comment tester

### Option 1: Via l'application Rails

1. **Démarrer le serveur Rails**
   ```bash
   rails server
   ```

2. **Ouvrir l'application dans le navigateur**
   ```
   http://localhost:3000
   ```

3. **Créer une commande test**
   - Se connecter avec un compte utilisateur
   - Ajouter des produits au panier
   - Aller au checkout
   - Sélectionner une adresse de livraison
   - Choisir une zone et un créneau
   - **Sélectionner "PayDunya" comme méthode de paiement**
   - Cliquer sur **"Valider et payer"**

4. **Vous serez automatiquement redirigé vers PayDunya**
   - URL du type: `https://paydunya.com/sandbox-checkout/invoice/test_XXXXX`

5. **Effectuer un paiement test sur PayDunya**
   - Choisir Wave / Orange Money / Free Money / Carte
   - Utiliser les numéros de test fournis par PayDunya

6. **Retour automatique sur votre application**
   - URL: `http://localhost:3000/paydunya/success?token=test_XXXXX`
   - Le paiement est vérifié automatiquement
   - La commande est marquée comme "processing"
   - Affichage de la confirmation

### Option 2: Test direct avec le script

```bash
ruby test_paydunya_redirect_flow.rb
```

Ce script crée une invoice test et affiche l'URL de paiement à ouvrir dans le navigateur.

---

## 📝 Configuration requise (déjà faite)

✅ Variables d'environnement dans `.env`:
```bash
PAYDUNYA_MASTER_KEY=qmR4BzHY-Pxvj-C89u-8B0G-4MdkKeygwCIe
PAYDUNYA_PRIVATE_KEY=test_private_Oswl7zByAb3CcrKwKKl1PChnZ9L
PAYDUNYA_TOKEN=ZIZYuDDbEOvVRYeSbUUp
PAYDUNYA_MODE=test
PAYDUNYA_STORE_NAME=aaApps
PAYDUNYA_STORE_URL=http://localhost:3000
```

✅ Méthode de paiement dans la base de données:
```ruby
PaymentMethod.create!(
  code: "paydunya",
  name: "PayDunya (Mobile Money & Carte)",
  provider: "paydunya",
  method_type: "online",
  is_active: true
)
```

✅ Routes de callback:
```ruby
# config/routes.rb
get  '/paydunya/success', to: 'paydunya_callbacks#success'
get  '/paydunya/cancel',  to: 'paydunya_callbacks#cancel'
post '/paydunya/ipn',     to: 'paydunya_callbacks#ipn'
```

---

## 🎨 Interface utilisateur

La vue `app/views/client/orders/new.html.erb` affiche déjà:

### Section de paiement PayDunya

```html
<div class="bg-blue-50 border border-blue-200 rounded-lg p-6">
  <h3 class="font-semibold text-blue-900 mb-3">
    💳 Paiement en ligne sécurisé
  </h3>
  <p class="text-blue-700 mb-4">
    Après avoir cliqué sur "Valider et payer", 
    vous serez redirigé vers notre page de paiement sécurisée.
  </p>
  
  <div class="bg-white rounded-lg p-4 mb-4">
    <p class="font-medium mb-3">Options de paiement disponibles :</p>
    <div class="grid grid-cols-2 gap-3">
      <div>💱 Wave Mobile Money</div>
      <div>🍊 Orange Money</div>
      <div>💰 Free Money</div>
      <div>💳 Carte bancaire</div>
    </div>
  </div>
  
  <ul class="text-sm space-y-2">
    <li>✓ Transaction 100% sécurisée</li>
    <li>✓ Choix du mode de paiement sur la page suivante</li>
    <li>✓ Confirmation immédiate de votre commande</li>
  </ul>
</div>
```

### Bouton de validation

```html
<%= form.submit "Valider et payer",
    class: "flex-1 px-6 py-3 bg-[#551694] text-white rounded-lg 
           font-semibold hover:bg-[#6a1fa8] transition-colors" %>
```

---

## 🔐 Sécurité

Toutes les bonnes pratiques sont déjà implémentées:

✅ **Clés API côté serveur uniquement** - Jamais exposées au client  
✅ **Vérification côté serveur** - Le statut est toujours vérifié via l'API PayDunya  
✅ **Transaction dans la base de données** - Garantit la cohérence des données  
✅ **Logs détaillés** - Pour le débogage et l'audit  
✅ **Gestion des erreurs** - Messages d'erreur clairs pour l'utilisateur  

---

## 📊 Logs pour le débogage

Les logs Rails montrent tout le processus:

```
[Client::OrdersController] Début création commande - user_id: 1, cart_id: 5
[Checkout::FinalizeOrderService] Début finalisation commande - user_id: 1, cart_id: 5
[Checkout::FinalizeOrderService] Order créée - order_id: 123, montant: 15000
[Checkout::FinalizeOrderService] Payment créé - payment_id: 456, méthode: PayDunya
[PayDunya HTTP] Création invoice checkout - order_id: 123, montant: 15000
[PayDunya HTTP] Réponse: 200 - {"response_code":"00","token":"test_ABC123",...}
[PayDunya HTTP] Invoice créée - token: test_ABC123, url: https://paydunya.com/...
[Client::OrdersController] Redirection vers PayDunya - url: https://paydunya.com/...

... Client paie sur PayDunya ...

[PaydunyaCallbacksController] Callback success - token: test_ABC123
[PayDunya] Vérification statut - payment_id: 456, token: test_ABC123
[PayDunya] Statut vérifié - status: completed
✅ Paiement confirmé avec succès!
```

---

## ⚡ En résumé

### Ce qui fonctionne déjà

1. ✅ Sélection de PayDunya comme méthode de paiement
2. ✅ Clic sur "Valider et payer"
3. ✅ Création automatique de l'invoice PayDunya
4. ✅ Redirection automatique vers la page de paiement PayDunya
5. ✅ Paiement sur PayDunya (Wave, Orange Money, Free Money, Carte)
6. ✅ Retour automatique après paiement
7. ✅ Vérification automatique du statut
8. ✅ Mise à jour de la commande et du paiement
9. ✅ Affichage de la confirmation

### Ce qu'il faut faire

**RIEN !** 🎉 

Il suffit de:
1. Démarrer votre serveur Rails
2. Créer une commande
3. Sélectionner PayDunya
4. Cliquer sur "Valider et payer"
5. Payer sur PayDunya
6. Revenir automatiquement sur votre site

---

## 🆘 Support

Si vous rencontrez un problème:

1. **Vérifier les logs Rails**
   ```bash
   tail -f log/development.log
   ```

2. **Tester la connexion à l'API**
   ```bash
   ruby test_paydunya_redirect_flow.rb
   ```

3. **Vérifier la configuration**
   ```bash
   rails runner "puts ENV['PAYDUNYA_MASTER_KEY']"
   ```

4. **Consulter la documentation**
   - `docs/PAYDUNYA_PAR_CURL_GUIDE.md`
   - `PAYDUNYA_INTEGRATION.md`
   - `PAYDUNYA_FRONTEND_GUIDE.md`

---

**Dernière mise à jour**: Décembre 2024  
**Version de l'intégration**: 1.0 (Complète et fonctionnelle)
