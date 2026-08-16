# Service SMS - Documentation

## Vue d'ensemble

Le service SMS permet d'envoyer des SMS via le provider LAM de manière unifiée. L'architecture est modulaire et permet d'ajouter facilement de nouveaux providers si nécessaire.

## Architecture

```
app/services/sms/
├── sms_service.rb              # Service principal pour envoyer des SMS
└── providers/
    ├── base_provider.rb        # Interface de base pour tous les providers
    └── lam_service.rb          # Provider LAM (utilise Net::HTTP natif)
```

## Configuration

### Variables d'environnement

```bash
# Activer/désactiver l'envoi de SMS
SEND_SMS_ENABLED=true

# Choisir le provider (défaut: lam_service)
SMS_PROVIDER=lam_service

# Configuration pour LAM Service
LAM_API_URL=https://api.lam-service.com
LAM_SENDER=TUKKIJAMM
LAM_ACCOUNT_ID=your_account_id
LAM_PASSWORD=your_password
LAM_RET_ID=your_ret_id
LAM_RET_URL=your_ret_url
LAM_CRM_API_KEY=your_api_key
```

## Utilisation

### Envoyer un SMS

```ruby
# Utilisation basique
Sms::SmsService.new.send_sms(
  to: "221776857298",
  message: "Votre code de vérification: 12345",
  sms_type: "verification"
)

# Spécifier un provider particulier
Sms::SmsService.new.send_sms(
  to: "221776857298",
  message: "Hello!",
  sms_type: "notification",
  provider: "lam_service"
)
```

### Vérifier les crédits

```ruby
# Vérifier les crédits du provider par défaut
credits = Sms::SmsService.new.check_credits
puts "Balance: #{credits[:balance]} #{credits[:currency]}"

# Vérifier les crédits d'un provider spécifique
credits = Sms::SmsService.new.check_credits(provider: "lam_service")
```

### Utilisation directe d'un provider

```ruby
# Utiliser directement le provider LAM
provider = Sms::Providers::LamService.new
result = provider.send(to: "221776857298", message: "Hello!")
credits = provider.credits
```

## Modèle SmsMessage

Chaque SMS envoyé est enregistré dans la table `sms_messages` avec les informations suivantes:

- `from`: Expéditeur
- `to`: Destinataire
- `body`: Contenu du message
- `status`: Statut (pending, sending, sent, failed)
- `sms_type`: Type de SMS (verification, notification, alert)
- `provider`: Nom du provider utilisé
- `provider_response`: Réponse du provider (JSON)

### Requêtes utiles

```ruby
# SMS envoyés avec succès
SmsMessage.sent.recent

# SMS en échec
SmsMessage.failed.recent

# SMS par provider
SmsMessage.by_provider("lam_service").sent

# Statistiques
SmsMessage.group(:status).count
SmsMessage.group(:provider).count
```

## Ajouter un nouveau provider

1. Créer une nouvelle classe dans `app/services/sms/providers/` qui hérite de `BaseProvider`:

```ruby
# frozen_string_literal: true

module Sms
  module Providers
    class MonNouveauProvider < BaseProvider
      def initialize
        # Configuration du provider
      end

      def send(to:, message:)
        # Implémenter l'envoi
        {
          success: true,
          message: "SMS envoyé",
          provider_response: { ... }
        }
      end

      def credits
        # Implémenter la vérification des crédits
        {
          success: true,
          balance: 100.0,
          currency: "XOF",
          provider_response: { ... }
        }
      end
    end
  end
end
```

2. Ajouter le provider dans `SmsService#get_provider`:

```ruby
when "mon_nouveau_provider"
  Providers::MonNouveauProvider.new
```

3. Ajouter le provider dans `SmsMessage::PROVIDERS`:

```ruby
PROVIDERS = %w[lam_service mon_nouveau_provider].freeze
```

4. Configurer les variables d'environnement nécessaires

## Migration de l'ancien code

Si vous utilisez actuellement `SmsSender`, vous pouvez migrer vers le nouveau service:

```ruby
# Ancien code
SmsSender.send_sms(phone_number, text)

# Nouveau code
Sms::SmsService.new.send_sms(
  to: phone_number,
  message: text,
  sms_type: "notification"
)
```

## Gestion des erreurs

Le service gère automatiquement les erreurs et met à jour le statut du `SmsMessage`:

- `pending`: SMS créé mais pas encore envoyé
- `sending`: SMS en cours d'envoi
- `sent`: SMS envoyé avec succès
- `failed`: Échec de l'envoi

Les erreurs sont loggées et la réponse du provider est stockée dans `provider_response`.

## Tests

Pour tester sans envoyer de vrais SMS, désactivez l'envoi:

```bash
SEND_SMS_ENABLED=false
```

Les SMS seront créés dans la base de données mais ne seront pas envoyés.

