import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="payment-selection"
export default class extends Controller {
  static targets = ["cashRadio", "onlineRadio", "onlineLabel"]

  connect() {
    // Initialiser l'état selon la sélection actuelle
    this.updateState()
    
    // Stocker la référence à la fonction liée pour pouvoir la retirer plus tard
    this.boundHandleOnlineLabelClick = this.handleOnlineLabelClick.bind(this)
    
    // Permettre de cliquer sur les labels même quand les options sont visuellement désactivées
    this.onlineLabelTargets.forEach(label => {
      label.addEventListener('click', this.boundHandleOnlineLabelClick)
    })
  }

  disconnect() {
    // Nettoyer les event listeners
    if (this.boundHandleOnlineLabelClick) {
      this.onlineLabelTargets.forEach(label => {
        label.removeEventListener('click', this.boundHandleOnlineLabelClick)
      })
    }
  }

  handleOnlineLabelClick(event) {
    // Si cash est sélectionné, permettre quand même de cliquer sur les options en ligne
    if (this.hasCashRadioTarget && this.cashRadioTarget.checked) {
      // Empêcher le comportement par défaut du label
      event.preventDefault()
      
      // Trouver le radio button correspondant au label cliqué
      const label = event.currentTarget
      const radio = label.querySelector('input[type="radio"]')
      
      if (radio && radio.disabled) {
        // Désélectionner cash d'abord
        this.cashRadioTarget.checked = false
        // Réactiver toutes les options
        this.reactivateOnlineOptions()
        // Sélectionner l'option cliquée après un petit délai pour s'assurer que disabled est bien retiré
        setTimeout(() => {
          radio.checked = true
          radio.dispatchEvent(new Event('change', { bubbles: true }))
        }, 10)
      }
    }
  }

  cashSelected(event) {
    if (event.target.checked) {
      this.deactivateOnlineOptions()
    } else {
      this.reactivateOnlineOptions()
    }
  }

  onlineSelected(event) {
    if (event.target.checked) {
      // Désélectionner cash si une option en ligne est sélectionnée
      if (this.hasCashRadioTarget) {
        this.cashRadioTarget.checked = false
      }
      // Réactiver toutes les options en ligne pour permettre le changement
      this.reactivateOnlineOptions()
    }
  }

  reactivateOnlineOptions() {
    this.onlineRadioTargets.forEach(radio => {
      radio.disabled = false
    })
    this.onlineLabelTargets.forEach(label => {
      label.style.opacity = '1'
      label.style.cursor = 'pointer'
      // Toujours permettre les pointer events pour que les labels soient cliquables
      label.style.pointerEvents = 'auto'
    })
  }

  deactivateOnlineOptions() {
    this.onlineRadioTargets.forEach(radio => {
      radio.checked = false
      radio.disabled = true
    })
    this.onlineLabelTargets.forEach(label => {
      label.style.opacity = '0.5'
      // Garder pointerEvents à 'auto' pour permettre le clic même quand visuellement désactivé
      label.style.cursor = 'pointer'
      label.style.pointerEvents = 'auto'
    })
  }

  updateState() {
    // Mettre à jour l'état initial selon la sélection
    if (this.hasCashRadioTarget && this.cashRadioTarget.checked) {
      this.deactivateOnlineOptions()
    } else {
      this.reactivateOnlineOptions()
    }
  }
}
