# Service de Notifications Centralisé

## Vue d'ensemble

Le service de notifications centralisé (`Notifications::NotificationService`) permet d'envoyer des notifications via **SMS**, **WhatsApp** et/ou **Email** de manière unifiée et cohérente.

## Architecture

```
app/services/notifications/
├── base_notification.rb                    # Classe de base pour toutes les notifications
├── notification_service.rb                 # Service centralisé (API publique)
├── order_notifications/                    # Notifications liées aux commandes
│   ├── order_confirmation_notification.rb
│   ├── vendor_new_order_notification.rb
│   ├── order_status_change_notification.rb
│   └── order_item_delivered_notification.rb
├── verification_notifications.rb          # Notifications de vérification OTP
└── password_reset_notification.rb         # Notifications de réinitialisation de mot de passe
```

## Utilisation

### Notification de confirmation de commande

```ruby
Notifications::NotificationService.send_order_confirmation(
  order,
  send_sms: true,
  send_email: false
)
```

### Notification de nouvelle commande au vendeur

```ruby
Notifications::NotificationService.send_vendor_new_order(
  vendor: vendor,
  order: order,
  shop: shop,
  send_sms: false,  # TODO: Réactiver plus tard
  send_email: true
)
```

### Notification de changement de statut de commande

```ruby
Notifications::NotificationService.send_order_status_change(
  order: order,
  status: :processing,  # :processing, :shipped, :delivered, :canceled, :partial_delivery
  send_sms: false,  # TODO: Réactiver plus tard
  send_email: true
)
```

### Notification de code de vérification

```ruby
Notifications::NotificationService.send_verification_code(
  recipient: user,  # ou vendor
  code: "1234",
  channel: "sms",   # ou "whatsapp" ou "email"
  send_sms: true,
  send_whatsapp: false,  # Activer WhatsApp
  send_email: true  # Fallback si SMS/WhatsApp échoue
)
```

### Notification de réinitialisation de mot de passe

```ruby
Notifications::NotificationService.send_password_reset(
  recipient: user,
  reset_token: token,
  reset_url: url,
  send_sms: true,
  send_whatsapp: false,  # Activer WhatsApp
  send_email: true
)
```

## Créer une nouvelle notification

1. Créer une classe qui hérite de `BaseNotification`
2. Implémenter les méthodes protégées nécessaires :
   - `sms_message` : Le message SMS (retourne `nil` si pas de SMS)
   - `sms_type` : Le type de SMS (`verification`, `notification`, `alert`)
   - `mailer_class` : La classe du mailer
   - `mailer_method` : La méthode du mailer
   - `mailer_params` : Les paramètres pour le mailer

3. Ajouter une méthode dans `NotificationService` pour faciliter l'utilisation

Exemple :

```ruby
module Notifications
  class MyCustomNotification < BaseNotification
    def initialize(recipient:, custom_param:, **options)
      super(recipient: recipient, **options)
      @custom_param = custom_param
    end

    protected

    def sms_message
      "Message SMS avec #{@custom_param}"
    end

    def sms_type
      "notification"
    end

    def mailer_class
      MyCustomMailer
    end

    def mailer_method
      :custom_method
    end

    def mailer_params
      { custom_param: @custom_param }
    end
  end
end
```

## Canaux de notification

Le système supporte 3 canaux de notification :

1. **SMS** : Via le service SMS (LAM, etc.)
2. **WhatsApp** : Via l'API officielle Meta Business Cloud API
3. **Email** : Via ActionMailer (Rails)

Chaque notification peut être envoyée via un ou plusieurs canaux simultanément, avec fallback automatique.

## Avantages

1. **Centralisation** : Toutes les notifications passent par un seul point d'entrée
2. **Cohérence** : Même structure pour SMS, WhatsApp et Email
3. **Flexibilité** : Facile d'activer/désactiver chaque canal indépendamment
4. **Maintenabilité** : Code organisé et facile à étendre
5. **Testabilité** : Facile à tester et mocker
6. **Fallback automatique** : Gestion automatique du fallback SMS/WhatsApp → Email
7. **Multi-canal** : Support natif de plusieurs canaux simultanés

## TODO - Notifications à réactiver

Les notifications suivantes sont préparées mais désactivées (SMS commenté) :

- ✅ Nouvelle commande au vendeur (SMS)
- ✅ Commande en traitement (SMS)
- ✅ Commande expédiée (SMS)
- ✅ Commande livrée (SMS)
- ✅ Commande annulée (SMS)
- ✅ Article livré (SMS)

Pour les réactiver, il suffit de changer `send_sms: false` en `send_sms: true` dans les appels correspondants.

