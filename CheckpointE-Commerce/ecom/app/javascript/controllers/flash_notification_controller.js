import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="flash-notification"
export default class extends Controller {
  static values = {
    autoclose: Number
  }

  connect() {
    // Auto-close après le délai spécifié (en millisecondes)
    if (this.autocloseValue > 0) {
      this.timeoutId = setTimeout(() => {
        this.close()
      }, this.autocloseValue)
    }
  }

  disconnect() {
    // Nettoyer le timeout si le contrôleur est déconnecté
    if (this.timeoutId) {
      clearTimeout(this.timeoutId)
    }
  }

  close() {
    this.element.classList.add('animate-slide-out-right')
    
    // Supprimer uniquement la notification, jamais le conteneur
    // (le conteneur doit rester dans le DOM pour les futurs turbo_stream.append)
    setTimeout(() => {
      this.element.remove()
    }, 300)
  }
}
