import { Controller } from "@hotwired/stimulus"

// Empêche la double soumission d'un formulaire (double-clic / double-tap mobile).
// Utile sur les formulaires non-Turbo (data: { turbo: false }) qui ne bénéficient
// pas de la désactivation auto du bouton fournie par Turbo.
//
// Usage:
//   form: data-controller="submit-once" data-action="submit->submit-once#guard"
//   bouton submit: data-submit-once-target="button"
export default class extends Controller {
  static targets = ["button"]

  connect() {
    this.submitting = false
  }

  guard(event) {
    if (this.submitting) {
      event.preventDefault()
      return
    }
    this.submitting = true

    // On désactive le bouton APRÈS le début de la soumission (setTimeout 0) pour
    // que sa valeur soit tout de même envoyée avec le formulaire.
    if (this.hasButtonTarget) {
      setTimeout(() => {
        this.buttonTarget.disabled = true
        this.buttonTarget.classList.add("opacity-60", "cursor-not-allowed")
      }, 0)
    }
  }
}
