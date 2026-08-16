# Règles et Conventions - SIRA Platform

Ce document définit les règles et conventions à suivre dans tout le projet pour garantir la cohérence, l'ergonomie et la maintenabilité.

## 📋 Table des matières

1. [Validations et Formats](#validations-et-formats)
2. [Ergonomie des Formulaires](#ergonomie-des-formulaires)
3. [Conventions de Nommage](#conventions-de-nommage)
4. [Gestion des Erreurs](#gestion-des-erreurs)
5. [Messages Utilisateur](#messages-utilisateur)
6. [Sécurité](#sécurité)

---

## 📊 Graphiques avec Chartkick

**Utilisation** : Utiliser Chartkick pour tous les graphiques dans l'application

**Installation** :
```ruby
# Gemfile
gem "chartkick", "~> 5.2", ">= 5.2.1"
gem "groupdate", "~> 6.7"
```

**Configuration** :
```ruby
# config/importmap.rb
pin "chartkick", to: "chartkick.js"
pin "Chart.bundle", to: "Chart.bundle.js"

# app/javascript/application.js
import "chartkick"
import "Chart.bundle"
```

**Types de graphiques disponibles** :
- `line_chart` - Graphique en ligne
- `pie_chart` - Graphique en camembert
- `column_chart` - Graphique en colonnes
- `bar_chart` - Graphique en barres
- `area_chart` - Graphique en aires
- `scatter_chart` - Graphique de dispersion

**Exemple d'utilisation** :
```erb
<% 
  # Le modèle Transaction doit étendre Groupdate
  # class Transaction < ApplicationRecord
  #   extend Groupdate
  # end
  
  last_7_days = Transaction.where(created_at: 7.days.ago..Time.current)
  daily_transactions = last_7_days.group_by_day(:created_at).count
%>
<%= line_chart daily_transactions, 
    height: "300px",
    xtitle: "Date",
    ytitle: "Nombre de transactions",
    colors: ["#3B82F6"] %>
```

**Documentation** : https://chartkick.com/

## 🔍 Validations et Formats

### Numéros de Téléphone

**Format attendu** : `770000101` (sans indicatif dans les formulaires)
**Format stocké** : `+221770000101` (avec indicatif dans la base)

**Règles** :
- Les formulaires acceptent le numéro sans indicatif
- L'indicatif est sélectionné via `country_select_with_phone_code` helper
- **Validation** : Utilise `Phonelib` pour valider le numéro complet
- Unicité : `phone_number` + `country_code`

**Validation avec Phonelib** :
```ruby
# Dans le modèle User
validate :valid_phone_number

def valid_phone_number
  return if phone_number.blank? || country_code.blank?
  
  full_phone = "#{country_code}#{phone_number}"
  phone = Phonelib.parse(full_phone)
  
  unless phone.valid?
    errors.add(:phone_number, "n'est pas un numéro de téléphone valide")
  end
end
```

**Exemple** :
```ruby
# Dans les formulaires
phone_number: "770000101"
country_code: "+221"

# Stocké en base
country_code: "+221"
phone_number: "770000101"
```

### Indicatifs Pays

**Utilisation** : Utiliser `country_select_with_phone_code` helper avec Countries gem

**Règles** :
- Utiliser `ISO3166::Country` pour obtenir les indicatifs téléphoniques
- Afficher le drapeau emoji et le nom du pays
- Format : `🇸🇳 Sénégal (+221)`

**Exemple** :
```erb
<%= country_select_with_phone_code(f, :country_code,
    { selected: @user.country_code || "+221" },
    { class: FORM_FIELD_CLASSES, required: true }) %>
```

### Adresses Email

**Format** : Email standard avec normalisation automatique
**Règles** :
- Normalisation : `strip` + `downcase` automatique
- Unicité : email unique dans toute la base
- Optionnel : email peut être `nil` (certains utilisateurs n'ont que le téléphone)

**Exemple** :
```ruby
# Accepté
"Admin@SIRA.SN" → stocké comme "admin@sira.sn"
```

### Montants et Devises

**Format** : Décimal avec 2 décimales
**Précision** : `decimal(18, 2)` en base de données
**Devise par défaut** : `XOF` (Franc CFA)

**Règles** :
- Montant minimum : `0.01` (1 centime)
- Montant maximum : selon les limites de transaction
- Affichage : séparateur de milliers avec espace (ex: `125 450,00 XOF`)
- Validation : `numericality: { greater_than: 0 }`

**Exemple** :
```ruby
amount: 125450.50  # Stocké
# Affiché : "125 450,50 XOF"
```

### UID SIRAC

**Format** : 12 chiffres exactement
**Génération** : Automatique lors de la création
**Règles** :
- Format : `100000000001` à `999999999999`
- Unicité : garantie par la base de données
- Non modifiable après création

### Références de Transaction

**Format** : `TYPE-YYYYMMDD-XXXX` (ex: `TXN-20240115-A1B2`)
**Règles** :
- Génération automatique
- Unicité garantie
- Format lisible et traçable

**Exemples** :
- Transfert : `TXN-20240115-A1B2`
- Cash-in : `CASHIN-20240115-C3D4`
- Cash-out : `CASHOUT-20240115-E5F6`
- Settlement : `SETTLEMENT-20240115-G7H8`

### Dates

**Format d'affichage** : `DD/MM/YYYY` (ex: `15/01/2024`)
**Format avec heure** : `DD/MM/YYYY à HH:MM` (ex: `15/01/2024 à 14:30`)
**Format stocké** : `YYYY-MM-DD` (ISO 8601)

**Règles** :
- Utiliser `strftime` pour l'affichage
- Timezone : UTC en base, affichage selon le fuseau horaire de l'utilisateur

### Statuts

**Convention** : Toujours en minuscules, en anglais
**Règles** :
- Utiliser des enums pour tous les statuts
- Statuts possibles : `pending`, `active`, `completed`, `failed`, `blocked`, etc.
- Traduction pour l'affichage : utiliser `humanize` ou un helper

---

## 📐 Layout et Largeur des Pages

### Principe Full Width

**Règle fondamentale** : Toutes les pages et formulaires utilisent **full width** (largeur complète).

**Classes à utiliser** :
- ✅ `w-full` - Utiliser pour tous les conteneurs principaux
- ❌ `max-w-*` - Ne PAS utiliser de contraintes de largeur maximale
- ❌ `mx-auto` - Ne PAS centrer avec des marges automatiques

**Exemple correct** :
```erb
<div class="w-full">
  <div class="bg-white shadow-sm rounded-lg border border-gray-200">
    <!-- Contenu -->
  </div>
</div>
```

**Exemple incorrect** :
```erb
<div class="w-full max-w-2xl mx-auto">  <!-- ❌ À éviter -->
  <!-- Contenu -->
</div>
```

**Justification** : 
- Meilleure utilisation de l'espace disponible
- Expérience utilisateur optimale sur tous les écrans
- Cohérence visuelle dans toute l'application
- Formulaires plus ergonomiques avec plus d'espace

## 🎨 Ergonomie des Formulaires

### Principes UX/UI Fondamentaux

**1. Hiérarchie Visuelle**
- Titre principal : `text-2xl font-bold` avec description `text-sm text-gray-600`
- Sections clairement séparées avec `border-t border-gray-200`
- Espacement cohérent : `space-y-6` entre les sections principales

**2. Feedback Utilisateur**
- **Recherche en temps réel** : Pour les champs de recherche (téléphone, email, etc.)
- **Validation visuelle** : Icônes de succès/erreur à côté des champs
- **Indicateurs de chargement** : Spinners lors des recherches asynchrones
- **Messages contextuels** : Erreurs affichées directement sous le champ concerné

**3. Aide Contextuelle**
- **Placeholders explicites** : Exemples concrets (ex: "770000101")
- **Textes d'aide** : Sous chaque champ avec `text-xs text-gray-500`
- **Astuces** : Pour les champs complexes, ajouter des conseils pratiques
- **Boutons rapides** : Pour les montants fréquents (5k, 10k, 25k, 50k)

**4. Accessibilité**
- Labels clairs avec `*` pour les champs obligatoires
- Attributs HTML5 : `required`, `pattern`, `min`, `max`, `autocomplete`
- Contraste suffisant : texte gris foncé sur fond blanc
- Focus visible : `focus:ring-2 focus:ring-primary-500`

### Structure Standard

Tous les formulaires doivent suivre cette structure :

```erb
<div class="w-full max-w-2xl mx-auto">
  <!-- En-tête avec icône et description -->
  <div class="mb-6">
    <div class="flex items-center gap-3 mb-2">
      <div class="p-2 rounded-lg bg-primary-100">
        <!-- Icône SVG -->
      </div>
      <div>
        <h1 class="text-2xl font-bold text-gray-900">Titre</h1>
        <p class="mt-1 text-sm text-gray-600">Description</p>
      </div>
    </div>
  </div>

  <div class="bg-white shadow-sm rounded-lg border border-gray-200 overflow-hidden">
    <%= form_with ... do |f| %>
      <div class="px-6 py-6 space-y-6">
        <!-- Champs avec feedback visuel -->
        
        <!-- Actions -->
        <div class="flex items-center justify-end gap-4 pt-6 border-t border-gray-200">
          <%= link_to "Annuler", cancel_path, class: "..." %>
          <%= f.submit "Valider", class: "..." %>
        </div>
      </div>
    <% end %>
  </div>
</div>
```

### Champs Obligatoires vs Optionnels

**Règles** :
- Marquer visuellement les champs obligatoires avec `*` dans le label
- Utiliser `required: true` dans les champs HTML
- Afficher des messages d'aide sous chaque champ avec `text-xs text-gray-500`
- Utiliser `placeholder` pour guider l'utilisateur

**Exemple** :
```erb
<div>
  <%= f.label :phone_number, "Téléphone *", class: "block text-sm font-medium text-gray-700 mb-2" %>
  <%= f.text_field :phone_number, 
      placeholder: "770000101", 
      pattern: "[0-9]{7,15}",
      required: true, 
      class: "block w-full py-3 rounded-lg border-gray-300 shadow-sm focus:border-primary-500 focus:ring-primary-500 text-sm" %>
  <p class="mt-1 text-xs text-gray-500">
    <span class="font-medium">Astuce :</span> Entrez votre numéro sans indicatif (7 à 15 chiffres)
  </p>
  <% if @user.errors[:phone_number].any? %>
    <p class="mt-1 text-sm text-red-600 flex items-center gap-1">
      <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">...</svg>
      <%= @user.errors[:phone_number].first %>
    </p>
  <% end %>
</div>
```

### Recherche et Auto-complétion

**Règles** :
- Pour les champs de recherche (téléphone, email, nom), implémenter une recherche en temps réel
- Afficher un indicateur de chargement pendant la recherche
- Montrer les résultats de recherche dans un conteneur dédié
- Pré-remplir les champs associés si un résultat est trouvé

**Exemple** :
```erb
<div class="relative">
  <%= f.text_field :customer_phone, 
      data: { controller: "customer-search", action: "input->customer-search#search" } %>
  <div id="customer_phone_loading" class="absolute inset-y-0 right-0 pr-3 flex items-center hidden">
    <!-- Spinner -->
  </div>
</div>
<div id="customer_search_result" class="mt-2 hidden">
  <!-- Résultat de recherche -->
</div>
```

### Montants avec Sélection Rapide

**Règles** :
- Afficher la devise (XOF) à gauche du champ
- Proposer des boutons de sélection rapide pour les montants fréquents
- Formater automatiquement le montant à la saisie

**Exemple** :
```erb
<div>
  <%= f.label :amount, "Montant *", class: "..." %>
  <div class="relative">
    <div class="absolute inset-y-0 left-0 pl-3 flex items-center">
      <span class="text-gray-500 text-sm">XOF</span>
    </div>
    <%= f.number_field :amount, class: "pl-16 ..." %>
  </div>
  <div class="mt-2 flex items-center gap-4 text-xs">
    <button type="button" class="amount-quick-select" data-amount="5000">5 000</button>
    <button type="button" class="amount-quick-select" data-amount="10000">10 000</button>
  </div>
</div>
```

### Validation Côté Client

**Règles** :
- Toujours valider côté client ET côté serveur
- Afficher les erreurs de manière claire et contextuelle
- Utiliser les attributs HTML5 (`required`, `type="email"`, `min`, `max`, etc.)

### Messages d'Erreur

**Format** : Messages clairs et actionnables
**Règles** :
- Afficher les erreurs près du champ concerné
- Utiliser un style visuel distinct (rouge, icône d'alerte)
- Proposer des solutions quand possible

**Exemple** :
```erb
<% if @user.errors[:phone_number].any? %>
  <p class="mt-1 text-sm text-red-600">
    <%= @user.errors[:phone_number].first %>
  </p>
<% end %>
```

### Placeholders et Aides

**Règles** :
- Toujours fournir des placeholders explicites
- Ajouter des textes d'aide sous les champs complexes
- Utiliser des exemples concrets

**Exemple** :
```erb
<%= f.text_field :phone_number, placeholder: "770000101", class: "..." %>
<p class="mt-1 text-xs text-gray-500">
  Entrez votre numéro sans indicatif (ex: 770000101)
</p>
```

---

## 📝 Conventions de Nommage

### Modèles

**Règles** :
- Noms au singulier : `User`, `Transaction`, `Wallet`
- Associations : `has_many :transactions`, `belongs_to :user`
- Méthodes : `snake_case` pour les méthodes privées, `camelCase` pour les attributs JSON

### Contrôleurs

**Règles** :
- Noms au pluriel : `TransactionsController`, `UsersController`
- Actions RESTful : `index`, `show`, `new`, `create`, `edit`, `update`, `destroy`
- Actions personnalisées : verbe + nom (ex: `validate_transaction`, `block_user`)

### Services

**Règles** :
- Format : `VerbNounService` (ex: `CreateTransferService`, `ValidateTransactionService`)
- Un seul point d'entrée : `call` ou `execute`
- Retour : `{ success: true/false, ... }`

### Queries

**Règles** :
- Format : `NounQuery` (ex: `TransactionsQuery`, `UsersQuery`)
- Méthodes de classe : `self.method_name`
- Retour : ActiveRecord::Relation ou objet

### Vues

**Règles** :
- Partials : `_partial_name.html.erb`
- Organisées par contrôleur : `app/views/controller_name/`
- Layouts : `admin.html.erb` pour les espaces admin

---

## ⚠️ Gestion des Erreurs

### Services

**Format de retour standard** :
```ruby
{ success: true, transaction: @transaction }
# ou
{ success: false, error: "Message d'erreur" }
```

**Règles** :
- Toujours capturer les exceptions
- Retourner des messages d'erreur clairs
- Logger les erreurs pour le debugging

### Contrôleurs

**Règles** :
- Vérifier `result[:success]` avant de continuer
- Afficher les erreurs via `flash[:alert]`
- Rediriger vers la page appropriée en cas d'erreur

**Exemple** :
```ruby
result = CreateTransferService.new(...).call

if result[:success]
  flash[:notice] = "Transfert effectué avec succès."
  redirect_to transaction_path(result[:transaction])
else
  flash[:alert] = "Erreur : #{result[:error]}"
  redirect_to new_transfer_transactions_path
end
```

### Messages Flash

**Types** :
- `flash[:notice]` : Succès (vert)
- `flash[:alert]` : Erreur (rouge)
- `flash[:warning]` : Avertissement (orange)
- `flash[:info]` : Information (bleu)

**Règles** :
- Messages clairs et actionnables
- Éviter le jargon technique
- Utiliser le français pour les utilisateurs finaux

---

## 💬 Messages Utilisateur

### Ton et Style

**Règles** :
- Ton professionnel mais accessible
- Messages en français
- Éviter les messages techniques
- Proposer des actions quand possible

### Exemples de Messages

**Succès** :
- ✅ "Transfert effectué avec succès."
- ✅ "KYC soumis avec succès. En attente de validation."
- ✅ "Portefeuille gelé avec succès."

**Erreurs** :
- ❌ "Erreur lors du transfert : Solde insuffisant"
- ❌ "Client introuvable. Vérifiez le numéro de téléphone."
- ❌ "Limite quotidienne de transfert dépassée (50 000 XOF)"

**Avertissements** :
- ⚠️ "Cette action est irréversible. Êtes-vous sûr ?"
- ⚠️ "Votre KYC est en attente de validation."

---

## 🔒 Sécurité

### Validations

**Règles** :
- Toujours valider côté serveur (jamais uniquement côté client)
- Utiliser les validations ActiveRecord
- Vérifier les permissions avant chaque action

### Permissions

**Règles** :
- Utiliser `require_permission` dans les contrôleurs
- Vérifier les permissions dans les services
- Filtrer les données selon l'organisation de l'utilisateur

### Données Sensibles

**Règles** :
- Ne jamais logger les mots de passe
- Masquer les numéros de carte (afficher uniquement les 4 derniers chiffres)
- Chiffrer les données sensibles si nécessaire

---

## 📊 Formats d'Affichage

### Montants

**Helper à utiliser** : `number_with_delimiter(amount, delimiter: " ")`
**Format** : `125 450,50 XOF`

```ruby
number_with_delimiter(125450.50, delimiter: " ") # => "125 450,50"
```

### Dates

**Helper à utiliser** : `strftime`
**Formats standards** :
- Date seule : `%d/%m/%Y` → `15/01/2024`
- Date + heure : `%d/%m/%Y à %H:%M` → `15/01/2024 à 14:30`
- Date complète : `%d/%m/%Y à %H:%M:%S` → `15/01/2024 à 14:30:45`

### Statuts

**Helper à utiliser** : `humanize` ou helper personnalisé
**Exemple** :
```ruby
@transaction.status.humanize # => "Completed" → "Complétée"
```

### Numéros de Téléphone

**Format d'affichage** : `+221 77 000 01 01`
**Helper recommandé** : Créer un helper `format_phone_number`

---

## ✅ Checklist de Validation

Avant de créer/modifier un formulaire ou un modèle :

- [ ] Tous les champs obligatoires sont marqués visuellement
- [ ] Les validations sont présentes dans le modèle
- [ ] Les messages d'erreur sont clairs et actionnables
- [ ] Les placeholders et aides sont présents
- [ ] Les formats sont cohérents (téléphone, montant, date)
- [ ] Les permissions sont vérifiées
- [ ] Les messages flash sont appropriés
- [ ] Les données sont filtrées selon l'organisation
- [ ] Les logs d'audit sont créés pour les actions importantes

---

## 📚 Références

- [Architecture](./ARCHITECTURE.md) - Architecture en couches
- [Design System](./DESIGN_SYSTEM.md) - Système de design
- [Dashboard Guide](./DASHBOARD_GUIDE.md) - Guide du dashboard
