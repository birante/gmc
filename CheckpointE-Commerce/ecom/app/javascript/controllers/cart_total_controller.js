import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["itemTotal", "subtotal", "total", "item"]

  connect() {
    this.updateTotals()
    
    // Écouter les changements dans le DOM pour détecter les ajouts/suppressions d'items
    this.observer = new MutationObserver(() => {
      // Petit délai pour s'assurer que le DOM est complètement mis à jour
      setTimeout(() => this.updateTotals(), 50)
    })
    
    this.observer.observe(this.element, {
      childList: true,
      subtree: true,
      characterData: true
    })
  }
  
  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }

  updateTotals() {
    let subtotal = 0
    
    // Chercher tous les éléments avec le prix total (data-cart-total-target="itemTotal")
    this.itemTotalTargets.forEach(itemTotal => {
      const price = this.extractPrice(itemTotal.textContent)
      if (!isNaN(price) && price > 0) {
        subtotal += price
      }
    })
    
    // Si aucun itemTotal n'a été trouvé, chercher dans les items conteneurs
    if (this.itemTotalTargets.length === 0 && this.hasItemTarget) {
      this.itemTargets.forEach(item => {
        const totalElement = item.querySelector('[id^="total-price-"]')
        if (totalElement) {
          const price = this.extractPrice(totalElement.textContent)
          if (!isNaN(price) && price > 0) {
            subtotal += price
          }
        }
      })
    }

    // Formater et mettre à jour les totaux
    this.updateDisplays(subtotal)
  }

  updateDisplays(subtotal) {
    const formattedSubtotal = this.formatCurrency(subtotal)
    
    if (this.hasSubtotalTarget) {
      const unit = this.extractUnit(this.subtotalTarget.textContent)
      this.subtotalTarget.textContent = `${formattedSubtotal} ${unit}`.trim()
    }
    
    if (this.hasTotalTarget) {
      const unit = this.extractUnit(this.totalTarget.textContent)
      this.totalTarget.textContent = `${formattedSubtotal} ${unit}`.trim()
    }
  }

  extractPrice(text) {
    // Extraire le nombre en retirant tout sauf les chiffres
    const match = text.match(/\d+/g)
    if (match && match.length > 0) {
      // Recombiner les nombres trouvés (ex: "1 000" → 1000)
      return parseInt(match.join(''), 10)
    }
    return 0
  }

  extractUnit(text) {
    // Extraire l'unité (lettres à la fin)
    const match = text.match(/[A-Z]+/)
    return match ? match[0] : 'FCFA'
  }

  formatCurrency(amount) {
    // Formater avec espaces comme séparateurs de milliers
    return amount.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ' ')
  }
}
