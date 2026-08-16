import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidebar", "overlay"]

  connect() {
    // Gérer la fermeture avec la touche Escape
    this.boundEscapeHandler = this.handleEscape.bind(this)
    document.addEventListener("keydown", this.boundEscapeHandler)
  }

  disconnect() {
    // Nettoyer l'event listener
    document.removeEventListener("keydown", this.boundEscapeHandler)
    // Réactiver le scroll si le controller est détruit avec sidebar ouverte
    document.body.style.overflow = ''
  }

  toggle() {
    if (this.sidebarTarget.classList.contains('hidden')) {
      this.open()
    } else {
      this.close()
    }
  }

  open() {
    // Bloquer le scroll du body
    document.body.style.overflow = 'hidden'
    
    // Afficher l'overlay et la sidebar
    this.overlayTarget.classList.remove('hidden')
    this.sidebarTarget.classList.remove('hidden')
    
    // Ajouter transition d'opacité à l'overlay
    this.overlayTarget.classList.add('transition-opacity', 'duration-300')
    
    // Attendre un tick pour que le navigateur applique les classes display
    // puis déclencher l'animation slide-in
    setTimeout(() => {
      this.sidebarTarget.classList.remove('-translate-x-full')
      this.sidebarTarget.classList.add('translate-x-0')
      this.overlayTarget.classList.remove('opacity-0')
      this.overlayTarget.classList.add('opacity-100')
    }, 10)
  }

  close() {
    // Animation slide-out
    this.sidebarTarget.classList.add('-translate-x-full')
    this.sidebarTarget.classList.remove('translate-x-0')
    this.overlayTarget.classList.add('opacity-0')
    this.overlayTarget.classList.remove('opacity-100')
    
    // Masquer après l'animation (300ms)
    setTimeout(() => {
      this.sidebarTarget.classList.add('hidden')
      this.overlayTarget.classList.add('hidden')
      // Réactiver le scroll du body
      document.body.style.overflow = ''
    }, 300)
  }

  handleEscape(event) {
    if (event.key === "Escape" && !this.sidebarTarget.classList.contains('hidden')) {
      this.close()
    }
  }
}

