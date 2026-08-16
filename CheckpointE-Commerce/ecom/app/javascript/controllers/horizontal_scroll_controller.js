import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["scrollable", "leftButton", "rightButton"]

  connect() {
    this.updateButtonVisibility()
    // Écouter les événements de scroll pour mettre à jour les boutons
    this.scrollableTarget.addEventListener('scroll', () => this.updateButtonVisibility())
  }

  scrollLeft() {
    const scrollAmount = this.scrollableTarget.clientWidth * 0.8 // Scroll de 80% de la largeur visible
    this.scrollableTarget.scrollBy({
      left: -scrollAmount,
      behavior: 'smooth'
    })
  }

  scrollRight() {
    const scrollAmount = this.scrollableTarget.clientWidth * 0.8 // Scroll de 80% de la largeur visible
    this.scrollableTarget.scrollBy({
      left: scrollAmount,
      behavior: 'smooth'
    })
  }

  updateButtonVisibility() {
    const element = this.scrollableTarget
    const isAtStart = element.scrollLeft <= 0
    const isAtEnd = element.scrollLeft >= element.scrollWidth - element.clientWidth - 1

    // Masquer/afficher les boutons selon la position du scroll
    if (this.hasLeftButtonTarget) {
      this.leftButtonTarget.style.opacity = isAtStart ? '0.3' : '1'
      this.leftButtonTarget.style.cursor = isAtStart ? 'not-allowed' : 'pointer'
    }

    if (this.hasRightButtonTarget) {
      this.rightButtonTarget.style.opacity = isAtEnd ? '0.3' : '1'
      this.rightButtonTarget.style.cursor = isAtEnd ? 'not-allowed' : 'pointer'
    }
  }
}

