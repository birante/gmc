import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "form", "hidden", "input", "decrease", "increase", "display" ]
  static values = {
    max: Number,
    current: Number
  }

  connect() {
    if (!this.hasInputTarget && !this.hasDisplayTarget) return

    // Toujours parser/valider currentValueValue, même si Stimulus l'a initialisé
    // Car il peut être une string ou undefined
    let parsedValue = null
    
    if (this.hasCurrentValue) {
      // Si Stimulus a initialisé la valeur, la parser en nombre
      parsedValue = this._parseNumber(this.currentValueValue, null)
    }
    
    // Si la valeur parsée est invalide, essayer de la lire depuis le DOM
    if (parsedValue === null || isNaN(parsedValue)) {
      if (this.hasDisplayTarget && this.displayTarget.textContent.trim()) {
        parsedValue = this._parseNumber(this.displayTarget.textContent.trim(), null)
      } else if (this.hasInputTarget && this.inputTarget.value) {
        parsedValue = this._parseNumber(this.inputTarget.value, null)
      }
    }
    
    // Si toujours pas de valeur valide, utiliser 1 par défaut
    if (parsedValue === null || isNaN(parsedValue) || parsedValue < 1) {
      parsedValue = 1
    }
    
    // S'assurer que currentValueValue est toujours un nombre valide
    this.currentValueValue = parsedValue

    if (!this.hasMaxValue && this.hasInputTarget) {
      const maxAttribute = this._parseNumber(this.inputTarget.getAttribute("max"), null)
      if (maxAttribute !== null) {
        this.maxValue = maxAttribute
      }
    }

    this._syncDisplay()
  }

  disconnect() {
    // Nothing to cleanup for now
  }

  increase(event) {
    event.preventDefault()

    if (this._isAtOrAboveMax()) return

    // S'assurer que currentValueValue est un nombre avant de faire l'opération
    const current = this._parseNumber(this.currentValueValue, 1)
    this._setHiddenDelta(1)
    this.currentValueValue = current + 1
    this._syncDisplay()
    this._submitForm()
  }

  decrease(event) {
    event.preventDefault()

    // S'assurer que currentValueValue est un nombre avant de faire l'opération
    const current = this._parseNumber(this.currentValueValue, 1)
    
    if (current > 1) {
      this._setHiddenDelta(-1)
      this.currentValueValue = current - 1
      this._syncDisplay()
      this._submitForm()
    } else if (current === 1) {
      // Removing the last item
      this._setHiddenDelta(-1)
      this.currentValueValue = 0
      this._syncDisplay()
      this._submitForm()
    }
  }

  validate(event) {
    event.preventDefault()

    const enteredValue = this._parseNumber(this.inputTarget.value, this.currentValueValue || 1)
    const clampedValue = this._clampQuantity(enteredValue)
    const difference = clampedValue - this.currentValueValue

    if (difference === 0) {
      // Reset the input to the current value (in case user typed invalid data)
      this._syncDisplay()
      return
    }

    this._setHiddenDelta(difference)
    this.currentValueValue = clampedValue
    this._submitForm()
  }

  currentValueValueChanged() {
    this._syncDisplay()
  }

  maxValueChanged() {
    this._updateButtonsState()
  }

  _submitForm() {
    if (!this.hasFormTarget) return

    if (typeof this.formTarget.requestSubmit === "function") {
      this.formTarget.requestSubmit()
    } else {
      this.formTarget.submit()
    }
    
    // Mettre à jour les totaux du panier après soumission
    setTimeout(() => {
      this._updateCartTotals()
    }, 100)
  }
  
  _updateCartTotals() {
    // Trouver et déclencher la mise à jour du contrôleur cart-total
    const cartTotalController = this.application.getControllerForElementAndIdentifier(
      document.querySelector('[data-controller~="cart-total"]'),
      'cart-total'
    )
    if (cartTotalController) {
      cartTotalController.updateTotals()
    }
  }

  _setHiddenDelta(delta) {
    if (!this.hasHiddenTarget) return
    this.hiddenTarget.value = delta
  }

  _syncDisplay() {
    // S'assurer que currentValueValue est un nombre valide
    const value = this._parseNumber(this.currentValueValue, 1)
    
    if (this.hasInputTarget) {
      this.inputTarget.value = value
      this.inputTarget.dataset.current = value
    }

    if (this.hasDisplayTarget) {
      // Toujours afficher un nombre valide, jamais undefined ou NaN
      this.displayTarget.textContent = value
    }

    // Mettre à jour currentValueValue avec la valeur parsée
    this.currentValueValue = value
    
    this._updateButtonsState()
  }

  _updateButtonsState() {
    const current = this.currentValueValue
    const max = this.hasMaxValue ? this.maxValue : null

    if (this.hasDecreaseTarget) {
      // Permettre de passer à 0 (retirer du panier) depuis le sélecteur sur les fiches produit
      this.decreaseTarget.disabled = current <= 0
    }

    if (this.hasIncreaseTarget) {
      this.increaseTarget.disabled = max !== null ? current >= max : false
    }
  }

  _clampQuantity(value) {
    let result = value

    if (result < 1) result = 1
    if (this.hasMaxValue && result > this.maxValue) result = this.maxValue

    return result
  }

  _isAtOrAboveMax() {
    if (!this.hasMaxValue) return false
    return this.currentValueValue >= this.maxValue
  }

  _parseNumber(value, fallback) {
    const parsed = parseInt(value, 10)
    return Number.isNaN(parsed) ? fallback : parsed
  }
}

