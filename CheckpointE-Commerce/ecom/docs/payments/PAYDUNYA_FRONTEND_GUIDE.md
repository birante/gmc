# Guide d'intégration Front-End PayDunya

Ce guide explique comment intégrer PayDunya dans l'interface utilisateur de votre application.

## Vue d'ensemble

PayDunya supporte deux modes de paiement :

1. **PAR (Paiement Avec Redirection)** - Mode recommandé pour la plupart des cas
2. **PSR (Paiement Sans Redirection)** - Pour une expérience utilisateur plus fluide

## 1. Paiement Avec Redirection (PAR)

C'est le mode le plus simple et le plus sûr. Le client est redirigé vers la page de paiement PayDunya.

### Étape 1 : Formulaire de commande

Ajoutez simplement un champ caché dans votre formulaire de checkout :

```html
<form action="/client/orders" method="POST">
  <!-- Token CSRF -->
  <%= hidden_field_tag :authenticity_token, form_authenticity_token %>
  
  <!-- Autres champs de commande -->
  <%= hidden_field_tag :address_id, @selected_address&.id %>
  <%= hidden_field_tag :delivery_zone_id, @selected_zone&.id %>
  <%= hidden_field_tag :delivery_slot_id, @selected_slot&.id %>
  
  <!-- Sélection de la méthode de paiement -->
  <%= select_tag :payment_method_id, 
    options_from_collection_for_select(@payment_methods, :id, :name, @selected_payment_method_id),
    class: "form-select" 
  %>
  
  <!-- Type de paiement PayDunya (optionnel - PAR par défaut) -->
  <%= hidden_field_tag :paydunya_payment_type, "PAR" %>
  
  <button type="submit" class="btn btn-primary">
    Valider la commande
  </button>
</form>
```

### Étape 2 : Flux de paiement

1. L'utilisateur soumet le formulaire
2. Le serveur crée la commande et initialise le paiement PayDunya
3. L'utilisateur est automatiquement redirigé vers la page de paiement PayDunya
4. Après paiement, PayDunya redirige vers `/paydunya/success?token=XXX`
5. Le système vérifie le paiement et affiche la confirmation

### Étape 3 : Afficher les informations de paiement

Sur la page de confirmation de commande, vous pouvez afficher :

```erb
<% if @order.payments.any? %>
  <% payment = @order.payments.last %>
  
  <div class="payment-info">
    <h3>Paiement</h3>
    
    <% if payment.paydunya_invoice_url.present? %>
      <a href="<%= payment.paydunya_invoice_url %>" target="_blank" class="btn btn-outline-primary">
        Voir le reçu PayDunya
      </a>
    <% end %>
    
    <dl>
      <dt>Méthode</dt>
      <dd><%= payment.payment_method.name %></dd>
      
      <dt>Statut</dt>
      <dd>
        <span class="badge badge-<%= payment.status %>">
          <%= t("payment.status.#{payment.status}") %>
        </span>
      </dd>
      
      <dt>Montant</dt>
      <dd><%= number_to_currency(payment.amount, unit: "F CFA") %></dd>
    </dl>
  </div>
<% end %>
```

## 2. Paiement Sans Redirection (PSR)

Mode plus avancé qui garde l'utilisateur sur votre site.

### Étape 1 : Initialiser le paiement

```html
<form id="checkout-form">
  <!-- Champs de commande normaux -->
  
  <!-- Pour PSR -->
  <%= hidden_field_tag :paydunya_payment_type, "PSR" %>
  <%= text_field_tag :phone_number, @user.full_phone_number, 
    placeholder: "+221 77 XXX XX XX",
    class: "form-control",
    required: true
  %>
  
  <button type="submit">Valider la commande</button>
</form>
```

### Étape 2 : Gérer la soumission avec AJAX

```javascript
document.getElementById('checkout-form').addEventListener('submit', async (e) => {
  e.preventDefault();
  
  const formData = new FormData(e.target);
  
  try {
    const response = await fetch('/client/orders', {
      method: 'POST',
      headers: {
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
      },
      body: formData
    });
    
    const data = await response.json();
    
    if (data.success) {
      // Afficher le formulaire de confirmation
      showConfirmationCodeModal(data.token, data.phone_number);
    } else {
      alert(data.error);
    }
  } catch (error) {
    console.error('Erreur:', error);
  }
});
```

### Étape 3 : Modal de saisie du code de confirmation

```html
<!-- Modal Bootstrap -->
<div class="modal fade" id="confirmationModal" tabindex="-1">
  <div class="modal-dialog">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title">Code de confirmation</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
      </div>
      <div class="modal-body">
        <p>Un code de confirmation a été envoyé à votre numéro <strong id="phone-display"></strong></p>
        <p>Veuillez saisir le code reçu par SMS :</p>
        
        <input type="text" 
               id="confirmation-code" 
               class="form-control text-center" 
               placeholder="123456"
               maxlength="6"
               pattern="[0-9]{6}">
        
        <div id="error-message" class="alert alert-danger mt-3 d-none"></div>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">
          Annuler
        </button>
        <button type="button" class="btn btn-primary" onclick="confirmPayment()">
          Confirmer le paiement
        </button>
      </div>
    </div>
  </div>
</div>
```

### Étape 4 : Fonction de confirmation

```javascript
let currentPaymentToken = null;

function showConfirmationCodeModal(token, phoneNumber) {
  currentPaymentToken = token;
  document.getElementById('phone-display').textContent = phoneNumber;
  
  // Afficher le modal (Bootstrap)
  const modal = new bootstrap.Modal(document.getElementById('confirmationModal'));
  modal.show();
}

async function confirmPayment() {
  const code = document.getElementById('confirmation-code').value;
  const errorDiv = document.getElementById('error-message');
  
  if (!code || code.length !== 6) {
    errorDiv.textContent = 'Veuillez saisir un code à 6 chiffres';
    errorDiv.classList.remove('d-none');
    return;
  }
  
  try {
    const response = await fetch('/paydunya/charge', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
      },
      body: JSON.stringify({
        token: currentPaymentToken,
        confirmation_code: code
      })
    });
    
    const data = await response.json();
    
    if (data.success) {
      // Rediriger vers la page de commande
      window.location.href = data.order_url;
    } else {
      errorDiv.textContent = data.error;
      errorDiv.classList.remove('d-none');
    }
  } catch (error) {
    errorDiv.textContent = 'Une erreur est survenue. Veuillez réessayer.';
    errorDiv.classList.remove('d-none');
  }
}
```

## 3. Styling des badges de statut

```css
/* Statuts de paiement */
.badge-pending {
  background-color: #ffc107;
  color: #000;
}

.badge-processing {
  background-color: #17a2b8;
  color: #fff;
}

.badge-completed {
  background-color: #28a745;
  color: #fff;
}

.badge-failed {
  background-color: #dc3545;
  color: #fff;
}

.badge-refunded {
  background-color: #6c757d;
  color: #fff;
}
```

## 4. Traductions i18n

Ajoutez dans `config/locales/fr.yml` :

```yaml
fr:
  payment:
    status:
      pending: "En attente"
      processing: "En traitement"
      completed: "Payé"
      failed: "Échoué"
      refunded: "Remboursé"
    methods:
      paydunya: "PayDunya (Mobile Money & Carte)"
    messages:
      success: "Paiement confirmé avec succès"
      failed: "Le paiement a échoué"
      cancelled: "Le paiement a été annulé"
```

## 5. Gestion des erreurs

```javascript
// Fonction utilitaire pour afficher les erreurs
function showError(message) {
  // Exemple avec Toastr
  toastr.error(message);
  
  // Ou avec un simple alert
  // alert(message);
  
  // Ou avec un composant personnalisé
  // showNotification('error', message);
}

// Exemple d'utilisation dans le flux PSR
async function confirmPayment() {
  try {
    // ... code de confirmation
    
    if (!data.success) {
      showError(data.error || 'Une erreur est survenue');
    }
  } catch (error) {
    showError('Impossible de contacter le serveur. Vérifiez votre connexion.');
  }
}
```

## 6. Affichage des modes de paiement disponibles

```erb
<div class="payment-methods">
  <% @payment_methods.each do |method| %>
    <div class="payment-method-card">
      <input type="radio" 
             name="payment_method_id" 
             value="<%= method.id %>"
             id="pm-<%= method.id %>"
             <%= 'checked' if method.id == @selected_payment_method_id %>>
      
      <label for="pm-<%= method.id %>" class="payment-method-label">
        <% if method.provider == 'paydunya' %>
          <img src="/assets/paydunya-logo.png" alt="PayDunya" class="payment-logo">
          <span class="payment-name"><%= method.name %></span>
          <span class="payment-description">
            Mobile Money (Wave, Orange, Free) & Cartes Bancaires
          </span>
        <% else %>
          <span class="payment-name"><%= method.name %></span>
        <% end %>
      </label>
    </div>
  <% end %>
</div>
```

## 7. Tests en mode test

En mode test, utilisez ces numéros pour simuler différents scénarios :

- **+221 77 XXX XX XX** : Paiement réussi
- Consultez la documentation PayDunya pour d'autres numéros de test

## Support

Pour toute question :
- Consultez `PAYDUNYA_INTEGRATION.md` pour la documentation technique
- Exécutez `rails runner test_paydunya_integration.rb` pour vérifier l'installation
- Vérifiez les logs Rails pour le débogage : `tail -f log/development.log`

## Ressources

- Documentation officielle PayDunya : https://paydunya.com/developers/ruby
- Gem Ruby : https://github.com/paydunyadev/paydunya-ruby-master
