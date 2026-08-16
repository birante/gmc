import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "item", "dot", "prevButton", "nextButton"]
  static values = {
    itemsPerPage: { type: Number, default: 4 },
    currentPage: { type: Number, default: 0 }
  }

  connect() {
    this.currentPageValue = 0
    this.calculateItemsPerPage()
    this.updateView()
    
    // Recalculer le nombre d'items visibles au resize
    this.resizeHandler = this.handleResize.bind(this)
    window.addEventListener('resize', this.resizeHandler)
  }

  disconnect() {
    window.removeEventListener('resize', this.resizeHandler)
  }

  handleResize() {
    this.calculateItemsPerPage()
    // Réajuster la page courante si nécessaire
    if (this.currentPageValue >= this.totalPages) {
      this.currentPageValue = Math.max(0, this.totalPages - 1)
    }
    this.updateView()
  }

  calculateItemsPerPage() {
    // Ajuster le nombre d'items par page selon la taille de l'écran
    if (window.innerWidth < 640) {
      this.itemsPerPageValue = 2
    } else if (window.innerWidth < 1024) {
      this.itemsPerPageValue = 3
    } else {
      this.itemsPerPageValue = 4
    }
  }

  next() {
    if (this.currentPageValue < this.totalPages - 1) {
      this.currentPageValue++
      this.scrollToPage()
      this.updateView()
    }
  }

  previous() {
    if (this.currentPageValue > 0) {
      this.currentPageValue--
      this.scrollToPage()
      this.updateView()
    }
  }

  goToPage(event) {
    const page = parseInt(event.currentTarget.dataset.page, 10)
    if (page !== this.currentPageValue && page >= 0 && page < this.totalPages) {
      this.currentPageValue = page
      this.scrollToPage()
      this.updateView()
    }
  }

  scrollToPage() {
    if (!this.hasContainerTarget || !this.hasItemTarget) return
    
    const container = this.containerTarget
    const items = this.itemTargets
    
    if (items.length === 0) return
    
    const itemWidth = items[0].offsetWidth
    const gap = 10 // gap-2.5 = 10px
    const scrollAmount = this.currentPageValue * (itemWidth + gap) * this.itemsPerPageValue
    
    container.scrollTo({
      left: scrollAmount,
      behavior: 'smooth'
    })
  }

  updateView() {
    this.updateButtons()
    this.updateDots()
  }

  updateButtons() {
    const isDesktop = window.innerWidth >= 1024
    
    // Bouton précédent : visible seulement si on n'est pas à la première page
    if (this.hasPrevButtonTarget) {
      const showPrev = this.currentPageValue > 0 && isDesktop
      this.prevButtonTarget.classList.toggle('opacity-0', !showPrev)
      this.prevButtonTarget.classList.toggle('pointer-events-none', !showPrev)
      this.prevButtonTarget.classList.toggle('opacity-100', showPrev)
      this.prevButtonTarget.classList.toggle('pointer-events-auto', showPrev)
    }
    
    // Bouton suivant : visible seulement si on n'est pas à la dernière page
    if (this.hasNextButtonTarget) {
      const showNext = this.currentPageValue < this.totalPages - 1 && isDesktop
      this.nextButtonTarget.classList.toggle('opacity-0', !showNext)
      this.nextButtonTarget.classList.toggle('pointer-events-none', !showNext)
      this.nextButtonTarget.classList.toggle('opacity-100', showNext)
      this.nextButtonTarget.classList.toggle('pointer-events-auto', showNext)
    }
  }

  updateDots() {
    if (!this.hasDotTarget) return
    
    this.dotTargets.forEach((dot, index) => {
      const isActive = index === this.currentPageValue
      dot.classList.toggle('bg-gray-200', !isActive)
      dot.classList.toggle('bg-[#634c9f]', isActive)
    })
  }

  get totalPages() {
    if (!this.hasItemTarget) return 1
    return Math.ceil(this.itemTargets.length / this.itemsPerPageValue)
  }
}
