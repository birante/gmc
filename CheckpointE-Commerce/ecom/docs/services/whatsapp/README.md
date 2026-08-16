# Service WhatsApp - Documentation

## Vue d'ensemble

Le service WhatsApp permet d'envoyer des messages via l'API officielle Meta Business Cloud API. L'architecture est modulaire et suit le même pattern que le service SMS.

## Architecture

```
app/services/whatsapp/
├── whatsapp_service.rb              # Service principal pour envoyer des messages
└── providers/
    ├── base_provider.rb              # Interface de base pour tous les providers
    └── meta_cloud_api.rb             # Provider Meta Cloud API (officiel)
```

## Configuration

### Variables d'environnement requises

```bash
# Activer/désactiver l'envoi de WhatsApp
SEND_WHATSAPP_ENABLED=true

# Choisir le provider (défaut: meta_cloud_api)
WHATSAPP_PROVIDER=meta_cloud_api

# Configuration pour Meta Cloud API
WHATSAPP_API_URL=https://graph.facebook.com/v21.0
WHATSAPP_PHONE_NUMBER_ID=your_phone_number_id
WHATSAPP_BUSINESS_ACCOUNT_ID=your_business_account_id
WHATSAPP_ACCESS_TOKEN=your_access_token
WHATSAPP_VERIFY_TOKEN=your_verify_token  # Pour la vérification webhook
```

### Obtenir les credentials Meta

1. Créer un compte Meta Business : https://business.facebook.com
2. Créer une application WhatsApp : https://developers.facebook.com/apps
3. Configurer WhatsApp Business API
4. Obtenir le Phone Number ID et Access Token depuis le dashboard Meta

## Utilisation

### Envoyer un message texte libre

```ruby
Whatsapp::WhatsappService.new.send_message(
  to: "221776857298",
  message: "Votre code de vérification: 1234"
)
```

### Envoyer un message template

```ruby
Whatsapp::WhatsappService.new.send_message(
  to: "221776857298",
  message: "Message de fallback si template échoue",
  template_name: "verification_code",
  template_params: ["1234"]
)
```

### Vérifier les crédits

```ruby
credits = Whatsapp::WhatsappService.new.check_credits
puts "Status: #{credits[:success]}"
```

## Intégration avec le système de notifications

Le service WhatsApp est intégré dans le système de notifications centralisé :

```ruby
# Dans une notification, activer WhatsApp
Notifications::NotificationService.send_verification_code(
  recipient: user,
  code: "1234",
  channel: "whatsapp",
  send_whatsapp: true,
  send_sms: false,
  send_email: true  # Fallback si WhatsApp échoue
)
```

## Types de messages WhatsApp

### Messages texte libres
- Utilisables uniquement dans une fenêtre de 24h après un message du client
- Pas besoin de template approuvé
- Utilisés pour les conversations actives

### Messages template
- Nécessaires pour les messages hors fenêtre de 24h
- Doivent être approuvés par Meta
- Utilisés pour les notifications, codes de vérification, etc.

## Limitations et bonnes pratiques

1. **Templates approuvés** : Pour les messages de vérification et notifications, utilisez des templates approuvés
2. **Fenêtre de 24h** : Les messages texte libres ne fonctionnent que dans les 24h après un message client
3. **Format des numéros** : Format international sans + (ex: "221776857298")
4. **Rate limiting** : Respecter les limites de l'API Meta
5. **Fallback** : Toujours prévoir un fallback SMS ou Email

## Templates recommandés

Pour une utilisation optimale, créez et approuvez ces templates dans Meta Business :

1. **verification_code** : Code de vérification OTP
   - Paramètres : `{{1}}` (code)
   - Exemple : "Votre code de vérification: {{1}}"

2. **order_confirmation** : Confirmation de commande
   - Paramètres : `{{1}}` (numéro commande), `{{2}}` (montant)
   - Exemple : "Votre commande #{{1}} a été créée. Montant: {{2}}"

3. **order_status** : Changement de statut
   - Paramètres : `{{1}}` (numéro commande), `{{2}}` (statut)
   - Exemple : "Votre commande #{{1}} est {{2}}"

## Webhooks

Pour recevoir les messages entrants et les statuts de livraison, configurez les webhooks dans Meta Business :

```ruby
# TODO: Créer un contrôleur pour gérer les webhooks WhatsApp
# app/controllers/whatsapp/webhooks_controller.rb
```

## Documentation officielle

- Meta Business API : https://developers.facebook.com/docs/whatsapp/cloud-api
- Guide de démarrage : https://developers.facebook.com/docs/whatsapp/cloud-api/get-started
- Templates : https://developers.facebook.com/docs/whatsapp/message-templates

