import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="promo-toggle"
export default class extends Controller {
  static targets = ["fields", "checkbox"]

  connect() {
    // Controller connecté
  }

  toggle(event) {
    const checkbox = event.target
    const fieldsTarget = this.fieldsTarget
    
    if (fieldsTarget) {
      if (checkbox.checked) {
        fieldsTarget.classList.remove('hidden')
      } else {
        fieldsTarget.classList.add('hidden')
      }
    }
  }
}
