# 🚀 Guide Rapide - Paiement Paydunya pour Abonnements

## ⚡ Démarrage Rapide

### 1. Migration
```bash
rails db:migrate
```

### 2. Vérification
```bash
rails runner "puts SubscriptionPayment.count"
# => 0 (normal si aucun paiement n'a été effectué)
```

### 3. Configuration Paydunya
Vérifier que les variables d'environnement sont définies:
```bash
echo $PAYDUNYA_MASTER_KEY
echo $PAYDUNYA_PRIVATE_KEY
echo $PAYDUNYA_TOKEN
echo $PAYDUNYA_MODE  # test ou live
```

Si manquantes, les ajouter à `.env`:
```bash
PAYDUNYA_MASTER_KEY=votre_master_key
PAYDUNYA_PRIVATE_KEY=votre_private_key
PAYDUNYA_TOKEN=votre_token
PAYDUNYA_MODE=test
PAYDUNYA_STORE_URL=http://localhost:3000
```

---

## 🧪 Test en développement

### Scénario 1: Plan gratuit (ACCESS)
1. Créer un compte vendeur
2. Créer une boutique
3. Sélectionner le plan ACCESS
4. ✅ Subscription créée immédiatement (pas de paiement)

### Scénario 2: Plan payant (STARTER, BUSINESS, PARTNER)
1. Créer un compte vendeur
2. Créer une boutique
3. Sélectionner un plan payant (ex: STARTER)
4. 🔄 Redirection vers Paydunya
5. Effectuer le paiement test
6. 🔄 Redirection vers `/vendors/paydunya/subscription_success`
7. ✅ Subscription créée après confirmation du paiement

---

## 📝 URLs importantes

### Development (localhost:3000)
```
Callback Success: http://localhost:3000/fr/vendors/paydunya/subscription_success?token=XXX
Callback Cancel:  http://localhost:3000/fr/vendors/paydunya/subscription_cancel?token=XXX
IPN Webhook:      http://localhost:3000/fr/vendors/paydunya/subscription_ipn
```

### Production
```
Callback Success: https://aa.com/fr/vendors/paydunya/subscription_success?token=XXX
Callback Cancel:  https://aa.com/fr/vendors/paydunya/subscription_cancel?token=XXX
IPN Webhook:      https://aa.com/fr/vendors/paydunya/subscription_ipn
```

---

## 🔍 Debug

### Voir les paiements en cours
```bash
rails runner "SubscriptionPayment.pending.each { |sp| puts \"Shop: #{sp.shop.name} - Plan: #{sp.plan.code} - Amount: #{sp.amount}\" }"
```

### Voir les paiements complétés
```bash
rails runner "SubscriptionPayment.completed.each { |sp| puts \"Shop: #{sp.shop.name} - Plan: #{sp.plan.code} - Paid: #{sp.paid_at}\" }"
```

### Voir les erreurs
```bash
rails runner "SubscriptionPayment.failed.each { |sp| puts \"Shop: #{sp.shop.name} - Reason: #{sp.failure_reason}\" }"
```

### Consulter les logs
```bash
tail -f log/development.log | grep -E "PayDunya|SubscriptionPayment"
```

---

## 🎯 Points de vérification

- [ ] Migration exécutée: `rails db:migrate:status | grep subscription_payments`
- [ ] Modèle chargé: `rails runner "puts SubscriptionPayment.name"`
- [ ] PaymentMethod existe: `rails runner "puts PaymentMethod.find_by(code: 'paydunya')&.name"`
- [ ] Routes configurées: `rails routes | grep paydunya.*subscription`
- [ ] Variables ENV définies: `echo $PAYDUNYA_MASTER_KEY`

---

## 🆘 Problèmes courants

### Erreur: "PaymentMethod not found"
```bash
# Créer la méthode de paiement
rails runner "
  PaymentMethod.find_or_create_by(code: 'paydunya') do |pm|
    pm.name = 'PayDunya (Mobile Money & Carte)'
    pm.is_active = true
  end
"
```

### Erreur: "Invalid Masterkey"
- Vérifier que `PAYDUNYA_MASTER_KEY` est correcte
- Vérifier que `PAYDUNYA_MODE` correspond (test vs live)

### Paiement non confirmé
- Vérifier les logs: `tail -f log/development.log | grep PayDunya`
- Vérifier le statut dans l'admin: `/admin/subscription_payments`
- Tester manuellement la vérification:
  ```ruby
  # Dans rails console
  sp = SubscriptionPayment.last
  service = PaymentServices::SubscriptionPaydunyaService.new(
    subscription_payment: sp,
    shop: sp.shop,
    plan: sp.plan
  )
  result = service.check_payment_status
  puts result.success?
  ```

---

## 📱 Test avec Ngrok (pour IPN)

En développement, Paydunya ne peut pas atteindre `localhost`. Utiliser Ngrok:

```bash
# Terminal 1: Démarrer Rails
rails server

# Terminal 2: Démarrer Ngrok
ngrok http 3000

# Copier l'URL générée (ex: https://abcd1234.ngrok.io)
# Mettre à jour PAYDUNYA_STORE_URL
export PAYDUNYA_STORE_URL=https://abcd1234.ngrok.io
```

---

## 🎨 Admin Interface

Accéder à l'interface admin pour voir tous les paiements:
```
http://localhost:3000/admin/subscription_payments
```

Filtres disponibles:
- Par boutique
- Par plan
- Par statut (pending, completed, failed)
- Par date

---

## ✅ Commit

Une fois les tests validés:
```bash
git add .
git commit -m "✨ Ajouter le paiement Paydunya pour les abonnements vendeurs"
git push origin develop
```

---

**Temps d'implémentation:** ~2 heures  
**Complexité:** Moyenne  
**Impact:** ✅ Permet aux vendeurs de payer leur abonnement via Paydunya
