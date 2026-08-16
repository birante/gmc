import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["subCategorySelect", "categorySelect"]

  connect() {
    // Parser le JSON depuis le script tag
    try {
      const scriptTag = this.element.querySelector('script[data-category-selector-categories]')
      
      if (scriptTag) {
        const categoriesJson = scriptTag.textContent.trim()
        console.log('Raw categories JSON:', categoriesJson)
        
        if (categoriesJson) {
          this.categories = JSON.parse(categoriesJson)
        } else {
          this.categories = []
        }
      } else {
        console.warn('No categories script tag found')
        this.categories = []
      }
      
      console.log('CategorySelector connected', {
        hasCategorySelect: this.hasCategorySelectTarget,
        hasSubCategorySelect: this.hasSubCategorySelectTarget,
        categories: this.categories
      })
    } catch (error) {
      console.error('Error parsing categories JSON:', error)
      const scriptTag = this.element.querySelector('script[data-category-selector-categories]')
      console.error('Raw value:', scriptTag?.textContent)
      this.categories = []
    }
  }

  updateSubCategories(event) {
    const categoryId = parseInt(event.target.value)
    
    console.log('updateSubCategories called', { categoryId, categories: this.categories })
    
    if (!categoryId) {
      // Réinitialiser le select des sous-catégories
      this.clearSubCategories()
      return
    }

    // Trouver la catégorie sélectionnée
    const category = this.categories.find(cat => cat.id === categoryId)
    
    console.log('Found category', category)
    
    if (category && category.sub_categories) {
      // Mettre à jour le select des sous-catégories
      this.renderSubCategories(category.sub_categories)
    } else {
      this.clearSubCategories()
    }
  }

  renderSubCategories(subCategories) {
    if (!this.hasSubCategorySelectTarget) return

    const select = this.subCategorySelectTarget
    const currentValue = select.value
    
    // Vider le select
    select.innerHTML = ''
    
    // Ajouter l'option par défaut
    const defaultOption = document.createElement('option')
    defaultOption.value = ''
    defaultOption.textContent = select.dataset.prompt || 'Sélectionner'
    select.appendChild(defaultOption)
    
    // Ajouter les sous-catégories
    subCategories.forEach(subCat => {
      const option = document.createElement('option')
      option.value = subCat.id
      option.textContent = subCat.name
      if (currentValue && parseInt(currentValue) === subCat.id) {
        option.selected = true
      }
      select.appendChild(option)
    })
  }

  clearSubCategories() {
    if (!this.hasSubCategorySelectTarget) return

    const select = this.subCategorySelectTarget
    select.innerHTML = ''
    const defaultOption = document.createElement('option')
    defaultOption.value = ''
    defaultOption.textContent = select.dataset.prompt || 'Sélectionner'
    select.appendChild(defaultOption)
  }
}

