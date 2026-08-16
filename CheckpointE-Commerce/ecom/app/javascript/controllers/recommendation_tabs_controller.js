import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["filter", "content", "itemsCount", "loadMoreButton", "loadMoreContainer", "itemsGrid", "loading"]
  static values = {
    currentPage: { type: Number, default: 1 },
    currentTab: { type: String, default: "recommendations" },
    currentCategory: { type: String, default: "" },
    currentSort: { type: String, default: "relevant" },
    hasMore: { type: Boolean, default: true }
  }
  
  connect() {
    // Charger les produits immédiatement au chargement
    setTimeout(() => this.loadProducts(1, true), 100)
  }
  
  applyFilter(event) {
    event.preventDefault()
    event.stopPropagation()
    
    const filterType = event.currentTarget.dataset.filterType
    const filterValue = event.currentTarget.dataset.filterValue
    
    // Mettre à jour les valeurs
    if (filterType === "tab") {
      this.currentTabValue = filterValue
      // Mettre à jour les styles des boutons de filtre
      this.updateFilterButtons(filterType, filterValue)
    } else if (filterType === "category") {
      this.currentCategoryValue = filterValue || ""
    } else if (filterType === "sort") {
      this.currentSortValue = filterValue
    }
    
    // Réinitialiser à la page 1 et recharger
    this.currentPageValue = 1
    this.loadProducts(1, true)
  }
  
  updateFilterButtons(filterType, activeValue) {
    // Mettre à jour les styles des boutons de filtre
    this.filterTargets.forEach(button => {
      if (button.dataset.filterType === filterType) {
        const isActive = button.dataset.filterValue === activeValue
        if (isActive) {
          // Bouton actif
          button.classList.remove('bg-[#f3f6f9]', 'border-[#d1d5db]', 'text-[#3f4254]')
          button.classList.add('bg-[#551694]', 'border-[#551694]', 'text-white')
        } else {
          // Bouton inactif
          button.classList.remove('bg-[#551694]', 'border-[#551694]', 'text-white')
          button.classList.add('bg-[#f3f6f9]', 'border-[#d1d5db]', 'text-[#3f4254]')
        }
      }
    })
  }
  
  filterByCategory(event) {
    event.preventDefault()
    event.stopPropagation()
    const categoryId = event.currentTarget.dataset.categoryId || ""
    
    // Mettre à jour le texte du bouton de catégorie
    const categoryButton = event.currentTarget.closest('[data-controller="dropdown"]')?.querySelector('button')
    if (categoryButton) {
      const categoryName = event.currentTarget.textContent.trim()
      const span = categoryButton.querySelector('span')
      if (span) {
        span.textContent = categoryName
      }
    }
    
    // Mettre à jour la valeur et recharger
    this.currentCategoryValue = categoryId
    this.currentPageValue = 1
    this.loadProducts(1, true)
  }
  
  sortBy(event) {
    event.preventDefault()
    event.stopPropagation()
    const sortType = event.currentTarget.dataset.sort
    
    // Mettre à jour le texte du bouton de tri
    const sortButton = event.currentTarget.closest('[data-controller="dropdown"]')?.querySelector('button')
    if (sortButton) {
      const sortName = event.currentTarget.textContent.trim()
      const span = sortButton.querySelector('span')
      if (span) {
        span.textContent = sortName
      }
    }
    
    // Mettre à jour la valeur et recharger
    this.currentSortValue = sortType
    this.currentPageValue = 1
    this.loadProducts(1, true)
  }
  
  loadMore(event) {
    event.preventDefault()
    if (!this.hasMoreValue) return
    
    const nextPage = this.currentPageValue + 1
    this.loadProducts(nextPage, false)
  }
  
  loadProducts(page = 1, replace = true) {
    // Afficher le loading
    if (this.hasLoadingTarget) {
      this.loadingTarget.classList.remove('hidden')
    }
    
    // Construire les paramètres
    const params = new URLSearchParams()
    params.append('tab', this.currentTabValue)
    params.append('page', page)
    if (this.currentCategoryValue) {
      params.append('category_id', this.currentCategoryValue)
    }
    params.append('sort', this.currentSortValue)
    
    // Faire la requête AJAX
    fetch(`/client/items/recommendations?${params.toString()}`, {
      headers: {
        'Accept': 'text/html',
        'X-Requested-With': 'XMLHttpRequest'
      }
    })
    .then(response => {
      if (!response.ok) throw new Error('Network response was not ok')
      return response.text()
    })
    .then(html => {
      // Cacher le loading
      if (this.hasLoadingTarget) {
        this.loadingTarget.classList.add('hidden')
      }
      
      if (replace) {
        // Remplacer le contenu
        this.contentTarget.innerHTML = html
        this.currentPageValue = page
      } else {
        // Ajouter le contenu (load more)
        const tempDiv = document.createElement('div')
        tempDiv.innerHTML = html
        
        // Récupérer la grille de produits et le bouton load more
        const newItemsGrid = tempDiv.querySelector('[data-recommendation-tabs-target="itemsGrid"]')
        const newLoadMoreContainer = tempDiv.querySelector('[data-recommendation-tabs-target="loadMoreContainer"]')
        
        // Trouver la grille existante dans le contenu
        const existingItemsGrid = this.contentTarget.querySelector('[data-recommendation-tabs-target="itemsGrid"]')
        
        if (newItemsGrid && existingItemsGrid) {
          // Ajouter les nouveaux produits à la grille existante
          const newItems = newItemsGrid.querySelectorAll('[data-item]')
          newItems.forEach(item => {
            existingItemsGrid.appendChild(item)
          })
        }
        
        // Mettre à jour le bouton load more
        if (newLoadMoreContainer) {
          const existingLoadMore = this.contentTarget.querySelector('[data-recommendation-tabs-target="loadMoreContainer"]')
          if (existingLoadMore) {
            existingLoadMore.replaceWith(newLoadMoreContainer)
          } else {
            this.contentTarget.appendChild(newLoadMoreContainer)
          }
          this.hasMoreValue = true
        } else {
          // Plus de produits à charger
          const existingLoadMore = this.contentTarget.querySelector('[data-recommendation-tabs-target="loadMoreContainer"]')
          if (existingLoadMore) {
            existingLoadMore.remove()
          }
          this.hasMoreValue = false
        }
        
        this.currentPageValue = page
      }
      
      // Mettre à jour le compteur d'articles
      this.updateItemsCount()
    })
    .catch(error => {
      console.error('Error loading products:', error)
      if (this.hasLoadingTarget) {
        this.loadingTarget.classList.add('hidden')
      }
      if (replace) {
        this.contentTarget.innerHTML = '<p class="text-center text-red-500 py-8">Erreur lors du chargement des produits</p>'
      }
    })
  }
  
  updateItemsCount() {
    // Mettre à jour le compteur d'articles
    const items = this.contentTarget.querySelectorAll('[data-item]')
    if (this.hasItemsCountTarget && this.itemsCountTarget) {
      this.itemsCountTarget.textContent = items.length
    }
  }
}

