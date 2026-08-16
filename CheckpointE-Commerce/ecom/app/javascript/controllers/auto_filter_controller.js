import { Controller } from "@hotwired/stimulus"

// Contrôleur Stimulus pour filtres auto-soumis (réactifs) avec Turbo Stream
// Usage: data-controller="auto-filter"
//        data-auto-filter-debounce-value="300" (optionnel, défaut: 500ms pour le champ texte)
export default class extends Controller {
  static values = {
    debounce: { type: Number, default: 500 } // Délai en ms pour les champs texte
  }

  connect() {
    this.timeout = null
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  }

  // Soumission immédiate (checkboxes, radios, selects) avec Turbo Stream
  submit(event) {
    // Empêcher la soumission par défaut si c'est un submit
    if (event.type === 'submit') {
      event.preventDefault()
    }

    // Soumettre le formulaire avec Turbo (AJAX)
    this.submitForm()
  }

  // Soumission avec debounce (champs texte)
  debounceSubmit(event) {
    // Clear le timeout précédent
    if (this.timeout) {
      clearTimeout(this.timeout)
    }

    // Créer un nouveau timeout
    this.timeout = setTimeout(() => {
      this.submitForm()
    }, this.debounceValue)
  }

  // Soumettre le formulaire via Turbo (AJAX)
  submitForm() {
    // Créer une FormData à partir du formulaire
    const formData = new FormData(this.element)
    const searchParams = new URLSearchParams(formData)
    const url = `${this.element.action}?${searchParams.toString()}`

    // Faire la requête Turbo
    fetch(url, {
      method: 'GET',
      headers: {
        'Accept': 'text/vnd.turbo-stream.html, text/html, application/xhtml+xml'
      }
    })
    .then(response => response.text())
    .then(html => Turbo.renderStreamMessage(html))
    .catch(error => console.error('Erreur lors du filtrage:', error))
  }

  // Réinitialiser tous les filtres
  reset(event) {
    event.preventDefault()
    
    // Décocher toutes les checkboxes
    this.element.querySelectorAll('input[type="checkbox"]').forEach(checkbox => {
      checkbox.checked = false
    })

    // Vider tous les champs texte et nombre
    this.element.querySelectorAll('input[type="text"], input[type="number"], input[type="search"]').forEach(input => {
      input.value = ''
    })

    // Remettre les selects à leur première option
    this.element.querySelectorAll('select').forEach(select => {
      select.selectedIndex = 0
    })

    // Soumettre le formulaire vide
    this.submitForm()
  }
}
