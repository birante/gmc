import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sheet", "overlay"]

  connect() {
    // Fermer le sheet si on clique sur l'overlay
    this.overlayTarget.addEventListener('click', () => this.close())
    
    // Fermer le sheet avec la touche Escape
    this.handleKeydownBound = this.handleKeydown.bind(this)
    document.addEventListener('keydown', this.handleKeydownBound)
    
    // Écouter les événements personnalisés pour ouvrir le sheet
    this.handleOpenBound = () => this.open()
    document.addEventListener('cart-sheet:open', this.handleOpenBound)
    
    // Écouter la fin de la transition pour masquer complètement le sheet
    this.handleTransitionEndBound = this.handleTransitionEnd.bind(this)
    this.sheetTarget.addEventListener('transitionend', this.handleTransitionEndBound)
    
    // Vérifier si le panier doit être ouvert au chargement (via query parameter)
    const urlParams = new URLSearchParams(window.location.search)
    if (urlParams.get('cart') === 'open') {
      // Délai pour s'assurer que le DOM est prêt
      requestAnimationFrame(() => {
        this.open()
      })
    }
  }

  disconnect() {
    document.removeEventListener('keydown', this.handleKeydownBound)
    document.removeEventListener('cart-sheet:open', this.handleOpenBound)
    this.sheetTarget.removeEventListener('transitionend', this.handleTransitionEndBound)
  }

  open() {
    // Retirer hidden avant d'animer
    this.sheetTarget.classList.remove('hidden')
    this.overlayTarget.classList.remove('hidden')
    // Forcer un reflow pour que la transition fonctionne
    requestAnimationFrame(() => {
      // Retirer translate-x-full pour faire apparaître le sheet
      this.sheetTarget.classList.remove('translate-x-full')
    })
    // Empêcher le scroll du body quand le sheet est ouvert
    document.body.style.overflow = 'hidden'
    
    // Ajouter le query parameter à l'URL
    this._updateUrlParam('cart', 'open')
  }

  close() {
    // Ajouter translate-x-full pour faire disparaître le sheet
    this.sheetTarget.classList.add('translate-x-full')
    this.overlayTarget.classList.add('hidden')
    // Réactiver le scroll du body immédiatement
    document.body.style.overflow = ''
    // La classe hidden sera ajoutée après la transition via handleTransitionEnd
    
    // Retirer le query parameter de l'URL
    this._updateUrlParam('cart', null)
  }

  stopPropagation(event) {
    // Empêcher la propagation des événements à l'intérieur du panier
    // pour éviter qu'il ne se ferme lors des interactions
    event.stopPropagation()
  }

  handleTransitionEnd(event) {
    // Ne traiter que les transitions sur le sheet lui-même
    if (event.target === this.sheetTarget && this.sheetTarget.classList.contains('translate-x-full')) {
      // Masquer complètement le sheet après la transition
      this.sheetTarget.classList.add('hidden')
    }
  }

  handleKeydown(event) {
    // Ne fermer que si on appuie sur Escape ET qu'on n'est pas en train de modifier un input
    if (event.key === 'Escape' && 
        !this.sheetTarget.classList.contains('translate-x-full') &&
        event.target.tagName !== 'INPUT' &&
        event.target.tagName !== 'TEXTAREA') {
      this.close()
    }
  }

  _updateUrlParam(key, value) {
    const url = new URL(window.location.href)
    
    if (value === null || value === '') {
      // Retirer le paramètre
      url.searchParams.delete(key)
    } else {
      // Ajouter ou mettre à jour le paramètre
      url.searchParams.set(key, value)
    }
    
    // Mettre à jour l'URL sans recharger la page
    window.history.replaceState({}, '', url.toString())
  }
}

