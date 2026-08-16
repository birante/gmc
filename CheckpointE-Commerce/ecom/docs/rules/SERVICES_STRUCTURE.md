# Structure des Services

## 📁 Organisation par Dossiers

Les services sont organisés par domaine fonctionnel dans des sous-dossiers pour une meilleure maintenabilité et clarté.

```
app/services/
├── authentication/          # Services d'authentification
│   ├── authenticate_user_service.rb
│   └── create_session_service.rb
│
├── passwords/                # Services de gestion des mots de passe
│   ├── request_password_reset_service.rb
│   └── reset_password_service.rb
│
├── transactions/             # Services de transactions
│   ├── create_cash_operation_service.rb
│   ├── create_transfer_service.rb
│   └── validate_transaction_service.rb
│
├── users/                    # Services de gestion des utilisateurs
│   └── toggle_user_status_service.rb
│
├── wallets/                  # Services de gestion des wallets
│   └── toggle_wallet_status_service.rb
│
├── kyc_services/             # Services KYC
│   └── submit_kyc_service.rb
│
├── dashboard/                # Services de dashboard
│   └── load_dashboard_data_service.rb
│
├── exports/                  # Services d'export
│   ├── base_export_service.rb
│   ├── export_csv_service.rb
│   ├── export_pdf_service.rb
│   ├── export_excel_service.rb
│   └── export_report_service.rb
│
└── system/                   # Services système
    └── switch_country_service.rb
```

## 🔍 Utilisation

Rails charge automatiquement tous les fichiers dans `app/services/` et ses sous-dossiers. **Zeitwerk exige que les classes soient dans des modules correspondant aux dossiers** :

```ruby
# ✅ Correct - Utiliser les namespaces
service = Authentication::AuthenticateUserService.new(...)
service = Transactions::CreateCashOperationService.new(...)
service = Exports::ExportReportService.new(...)
service = Passwords::RequestPasswordResetService.new(...)
service = Users::ToggleUserStatusService.new(...)
service = Wallets::ToggleWalletStatusService.new(...)
service = Kyc::SubmitKycService.new(...)
service = Dashboard::LoadDashboardDataService.new(...)
service = System::SwitchCountryService.new(...)
```

## 📋 Services par Domaine

### Authentication (`authentication/`)
- **Authentication::AuthenticateUserService** : Authentification d'un utilisateur
- **Authentication::CreateSessionService** : Création d'une session utilisateur

### Passwords (`passwords/`)
- **Passwords::RequestPasswordResetService** : Demande de réinitialisation de mot de passe
- **Passwords::ResetPasswordService** : Réinitialisation du mot de passe

### Transactions (`transactions/`)
- **Transactions::CreateCashOperationService** : Création d'opérations cash-in/cash-out
- **Transactions::CreateTransferService** : Création de transferts entre clients
- **Transactions::ValidateTransactionService** : Validation/annulation/annulation de transactions

### Users (`users/`)
- **Users::ToggleUserStatusService** : Blocage/déblocage d'utilisateurs

### Wallets (`wallets/`)
- **Wallets::ToggleWalletStatusService** : Gel/dégel de wallets

### KYC (`kyc_services/`)
- **KycServices::SubmitKycService** : Soumission de documents KYC

### Dashboard (`dashboard/`)
- **Dashboard::LoadDashboardDataService** : Chargement des données du dashboard selon les rôles

### Exports (`exports/`)
- **Exports::ExportReportService** : Orchestrateur pour les exports
- **Exports::BaseExportService** : Classe de base pour les exports
- **Exports::ExportCsvService** : Export CSV
- **Exports::ExportPdfService** : Export PDF
- **Exports::ExportExcelService** : Export Excel

### System (`system/`)
- **System::SwitchCountryService** : Changement de pays de l'utilisateur

## 🎯 Avantages de cette Organisation

1. **Clarté** : Facile de trouver un service par domaine
2. **Maintenabilité** : Services regroupés par fonctionnalité
3. **Scalabilité** : Facile d'ajouter de nouveaux services dans le bon dossier
4. **Séparation des responsabilités** : Chaque domaine a son espace

## 📝 Ajouter un Nouveau Service

1. Identifier le domaine fonctionnel
2. Créer le fichier dans le dossier approprié
3. **Définir la classe dans le module correspondant au dossier**
4. Utiliser le namespace complet dans les contrôleurs

Exemple :
```ruby
# app/services/transactions/process_refund_service.rb
module Transactions
  class ProcessRefundService
    def initialize(...)
      # ...
    end
    
    def call
      # ...
    end
  end
end
```

Utilisation :
```ruby
service = Transactions::ProcessRefundService.new(...)
result = service.call
```

## ⚠️ Notes Importantes

- **Zeitwerk exige que les classes soient dans des modules correspondant aux dossiers**
- Les fichiers dans `app/services/authentication/` doivent définir `Authentication::ClassName`
- Les fichiers dans `app/services/transactions/` doivent définir `Transactions::ClassName`
- Les classes doivent avoir le même nom que le fichier (convention Rails)
- Tous les services utilisent maintenant des namespaces pour la compatibilité avec Zeitwerk
