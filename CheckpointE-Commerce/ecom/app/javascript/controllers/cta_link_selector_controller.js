import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["linkType", "categorySelect", "subCategorySelect", "itemSelect", "linkInput"]
  static values = {
    locale: String,
    categories: Array,
    subCategories: Array,
    items: Array
  }

  connect() {
    // Initialiser avec les données si présentes
    this.updateSubCategories()
  }

  linkTypeChanged(event) {
    const linkType = event.target.value
    this.updateVisibility(linkType)
    
    // Réinitialiser les sélecteurs
    if (this.hasCategorySelectTarget) this.categorySelectTarget.value = ""
    if (this.hasSubCategorySelectTarget) this.subCategorySelectTarget.value = ""
    if (this.hasItemSelectTarget) this.itemSelectTarget.value = ""
    
    // Réinitialiser le lien
    if (this.hasLinkInputTarget) {
      this.linkInputTarget.value = ""
    }
  }

  categoryChanged(event) {
    const categoryId = event.target.value
    this.updateSubCategories(categoryId)
    
    // Réinitialiser la sous-catégorie et le lien
    if (this.hasSubCategorySelectTarget) this.subCategorySelectTarget.value = ""
    if (this.hasLinkInputTarget) this.linkInputTarget.value = ""
  }

  subCategoryChanged(event) {
    this.generateLink()
  }

  itemChanged(event) {
    this.generateLink()
  }

  updateVisibility(linkType) {
    // Masquer tous les sélecteurs
    const selectors = [
      this.categorySelectTarget,
      this.subCategorySelectTarget,
      this.itemSelectTarget
    ].filter(Boolean)

    selectors.forEach(el => {
      if (el && el.closest('.mb-3')) {
        el.closest('.mb-3').classList.add('hidden')
      }
    })

    // Afficher les sélecteurs appropriés
    switch(linkType) {
      case 'category':
        if (this.hasCategorySelectTarget && this.categorySelectTarget.closest('.mb-3')) {
          this.categorySelectTarget.closest('.mb-3').classList.remove('hidden')
        }
        break
      case 'sub_category':
        if (this.hasCategorySelectTarget && this.categorySelectTarget.closest('.mb-3')) {
          this.categorySelectTarget.closest('.mb-3').classList.remove('hidden')
        }
        if (this.hasSubCategorySelectTarget && this.subCategorySelectTarget.closest('.mb-3')) {
          this.subCategorySelectTarget.closest('.mb-3').classList.remove('hidden')
        }
        break
      case 'item':
        if (this.hasItemSelectTarget && this.itemSelectTarget.closest('.mb-3')) {
          this.itemSelectTarget.closest('.mb-3').classList.remove('hidden')
        }
        break
      case 'custom':
        // Pour lien personnalisé, laisser le champ libre
        break
    }
  }

  updateSubCategories(categoryId = null) {
    if (!this.hasSubCategorySelectTarget || !this.hasCategorySelectTarget) return

    const selectedCategoryId = categoryId || this.categorySelectTarget.value
    const subCategorySelect = this.subCategorySelectTarget
    
    // Vider les options actuelles (sauf la première option vide)
    while (subCategorySelect.options.length > 1) {
      subCategorySelect.remove(1)
    }

    if (selectedCategoryId) {
      // Charger les sous-catégories depuis les données
      const categories = this.categoriesValue || []
      const category = categories.find(c => c.id == selectedCategoryId || c.id.toString() === selectedCategoryId.toString())
      
      if (category && category.sub_categories) {
        category.sub_categories.forEach(subCat => {
          const option = document.createElement('option')
          option.value = subCat.id
          option.textContent = subCat.name
          subCategorySelect.appendChild(option)
        })
      }
    }

    // Générer le lien si une catégorie est sélectionnée et c'est pour une catégorie (pas sous-catégorie)
    if (this.linkTypeTarget?.value === 'category') {
      this.generateLink()
    }
  }

  async loadSubCategories(categoryId) {
    try {
      const response = await fetch(`/fr/vendors/categories/${categoryId}/sub_categories.json`)
      if (response.ok) {
        const data = await response.json()
        const subCategorySelect = this.subCategorySelectTarget
        
        data.forEach(subCat => {
          const option = document.createElement('option')
          option.value = subCat.id
          option.textContent = subCat.name
          subCategorySelect.appendChild(option)
        })
      }
    } catch (error) {
      console.error('Erreur lors du chargement des sous-catégories:', error)
    }
  }

  generateLink() {
    if (!this.hasLinkInputTarget) return

    const linkType = this.linkTypeTarget?.value
    let generatedLink = ""

    switch(linkType) {
      case 'category':
        const categoryId = this.categorySelectTarget?.value
        if (categoryId) {
          const categories = this.categoriesValue || []
          const category = categories.find(c => c.id.toString() === categoryId.toString())
          if (category) {
            generatedLink = `/${this.localeValue || 'fr'}/categories/${category.slug}`
          }
        }
        break

      case 'sub_category':
        const subCategoryId = this.subCategorySelectTarget?.value
        const parentCategoryId = this.categorySelectTarget?.value
        if (subCategoryId && parentCategoryId) {
          const categories = this.categoriesValue || []
          const category = categories.find(c => c.id.toString() === parentCategoryId.toString())
          if (category) {
            const subCategory = category.sub_categories?.find(sc => sc.id.toString() === subCategoryId.toString())
            if (subCategory) {
              generatedLink = `/${this.localeValue || 'fr'}/categories/${category.slug}/${subCategory.slug}`
            }
          }
        }
        break

      case 'item':
        const itemId = this.itemSelectTarget?.value
        if (itemId) {
          const items = this.itemsValue || []
          const item = items.find(i => i.id.toString() === itemId.toString())
          if (item) {
            generatedLink = `/${this.localeValue || 'fr'}/produits/${item.slug}`
          }
        }
        break
    }

    if (generatedLink) {
      this.linkInputTarget.value = generatedLink
    }
  }
}
