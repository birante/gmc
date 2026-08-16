import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "categoryItem", "contentArea", "icon"]

  connect() {
    this._closeTimer = null
  }

  disconnect() {
    this._clearCloseTimer()
  }

  open(_event) {
    this._clearCloseTimer()
    this.positionMenu()
    this.menuTarget.classList.remove("hidden")
    this.selectFirstCategory()

    if (this.hasIconTarget) {
      this.iconTarget.classList.add("rotate-180")
    }
  }

  close() {
    this.menuTarget.classList.add("hidden")

    if (this.hasIconTarget) {
      this.iconTarget.classList.remove("rotate-180")
    }
  }

  positionMenu() {
    const categoryBar = this.element.closest(".border-b")
    if (!categoryBar) return

    const rect = categoryBar.getBoundingClientRect()
    this.menuTarget.style.top = `${rect.bottom}px`
  }

  keepMenuOpen(_event) {
    this._clearCloseTimer()
  }

  handleMouseLeave(event) {
    const relatedTarget = event.relatedTarget
    if (relatedTarget && (this.menuTarget.contains(relatedTarget) || this.element.contains(relatedTarget))) {
      return
    }

    this._closeTimer = setTimeout(() => {
      if (!this.menuTarget.matches(":hover") && !this.element.matches(":hover")) {
        this.close()
      }
    }, 120)
  }

  _clearCloseTimer() {
    if (this._closeTimer !== null) {
      clearTimeout(this._closeTimer)
      this._closeTimer = null
    }
  }

  // Gérer le survol d'une catégorie dans la sidebar
  selectCategory(event) {
    event.preventDefault()
    event.stopPropagation()
    const categoryId = event.currentTarget.dataset.categoryId
    
    // Retirer la sélection de toutes les catégories
    this.categoryItemTargets.forEach(item => {
      item.classList.remove("bg-gray-100", "text-[#551694]")
      item.classList.add("text-gray-700")
    })
    
    // Sélectionner la catégorie survolée
    const selectedItem = event.currentTarget
    selectedItem.classList.remove("text-gray-700")
    selectedItem.classList.add("bg-gray-100", "text-[#551694]")
    
    // Afficher le contenu correspondant
    this.showCategoryContent(categoryId)
  }

  selectFirstCategory() {
    if (this.categoryItemTargets.length > 0) {
      const firstCategory = this.categoryItemTargets[0]
      const categoryId = firstCategory.dataset.categoryId
      
      this.categoryItemTargets.forEach(item => {
        item.classList.remove("bg-gray-100", "text-[#551694]")
        item.classList.add("text-gray-700")
      })
      
      firstCategory.classList.remove("text-gray-700")
      firstCategory.classList.add("bg-gray-100", "text-[#551694]")
      
      this.showCategoryContent(categoryId)
    }
  }

  showCategoryContent(categoryId) {
    // Cacher tous les contenus
    this.contentAreaTargets.forEach(content => {
      content.classList.add("hidden")
    })
    
    // Afficher le contenu de la catégorie sélectionnée
    const content = this.contentAreaTargets.find(c => c.dataset.categoryId === categoryId)
    if (content) {
      content.classList.remove("hidden")
    }
  }
}
