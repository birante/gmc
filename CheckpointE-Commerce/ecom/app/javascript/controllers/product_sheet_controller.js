import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sheet", "overlay"]
  static values = {
    openOnLoad: Boolean,
    pageMode: Boolean,
    generatePreviewUrl: String
  }

  connect() {
    if (!this.pageModeValue) {
      this.overlayTarget.addEventListener('click', () => this.close())
      this.handleKeydownBound = this.handleKeydown.bind(this)
      document.addEventListener('keydown', this.handleKeydownBound)
      this.handleOpenBound = () => this.open()
      document.addEventListener('product-sheet:open', this.handleOpenBound)
      this.handleTransitionEndBound = this.handleTransitionEnd.bind(this)
      this.sheetTarget.addEventListener('transitionend', this.handleTransitionEndBound)
    }
    
    // Ouvrir automatiquement si openOnLoad est true (erreurs de validation)
    if (!this.pageModeValue && this.openOnLoadValue) {
      setTimeout(() => this.open(), 100)
    }
  }

  disconnect() {
    if (!this.pageModeValue) {
      document.removeEventListener('keydown', this.handleKeydownBound)
      document.removeEventListener('product-sheet:open', this.handleOpenBound)
      this.sheetTarget.removeEventListener('transitionend', this.handleTransitionEndBound)
    }
  }

  open() {
    this.sheetTarget.classList.remove('hidden')
    this.sheetTarget.classList.add('flex', 'flex-col')
    this.overlayTarget.classList.remove('hidden')
    requestAnimationFrame(() => {
      this.sheetTarget.classList.remove('translate-x-full')
    })
    document.body.style.overflow = 'hidden'
  }

  close() {
    this.sheetTarget.classList.add('translate-x-full')
    this.overlayTarget.classList.add('hidden')
    document.body.style.overflow = ''
  }

  handleTransitionEnd(event) {
    if (event.target === this.sheetTarget && this.sheetTarget.classList.contains('translate-x-full')) {
      this.sheetTarget.classList.add('hidden')
      this.sheetTarget.classList.remove('flex', 'flex-col')
    }
  }

  handleKeydown(event) {
    if (event.key === 'Escape' && !this.sheetTarget.classList.contains('translate-x-full')) {
      this.close()
    }
  }

  async generateAiPreview(event) {
    event.preventDefault()
    const button = event.currentTarget
    const resultContainer = document.getElementById('ai-preview-result')
    
    // Désactiver le bouton pendant la génération
    button.disabled = true
    button.innerHTML = `
      <svg class="animate-spin h-4 w-4" fill="none" viewBox="0 0 24 24">
        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
        <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
      </svg>
      Génération en cours...
    `
    
    // Récupérer les valeurs du formulaire
    const form = button.closest('form')
    const formData = new FormData(form)
    
    const params = {
      name: formData.get('item[name]'),
      description: formData.get('item[description]'),
      product_sub_category_id: formData.get('item[product_sub_category_id]'),
      price: formData.get('item[price]') || formData.get('item[default_price]'),
      currency_id: formData.get('item[currency_id]')
    }
    
    const previewUrl = this.generatePreviewUrlValue || '/fr/vendors/items/generate_ai_preview'
    try {
      const response = await fetch(previewUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify(params)
      })
      
      const data = await response.json()
      
      if (data.success && data.preview) {
        // Afficher la preview
        resultContainer.innerHTML = `
          <div class="space-y-3">
            <h4 class="font-semibold text-sm text-gray-900">Proposition générée :</h4>
            <div class="space-y-2 text-sm">
              <div>
                <label class="font-medium text-gray-700">Nom :</label>
                <p class="text-gray-600">${data.preview.name || 'Non généré'}</p>
              </div>
              <div>
                <label class="font-medium text-gray-700">Description :</label>
                <p class="text-gray-600">${data.preview.description || 'Non généré'}</p>
              </div>
              <div>
                <label class="font-medium text-gray-700">Meta Title :</label>
                <p class="text-gray-600">${data.preview.meta_title || 'Non généré'}</p>
              </div>
              <div>
                <label class="font-medium text-gray-700">Meta Description :</label>
                <p class="text-gray-600">${data.preview.meta_description || 'Non généré'}</p>
              </div>
            </div>
            <button type="button" 
                    class="w-full mt-3 px-3 py-2 bg-purple-600 text-white rounded-md hover:bg-purple-700 text-sm font-medium"
                    onclick="this.closest('form').querySelector('[name=\"item[name]\"]').value = '${(data.preview.name || '').replace(/'/g, "\\'")}'; this.closest('form').querySelector('[name=\"item[description]\"]').value = '${(data.preview.description || '').replace(/'/g, "\\'").replace(/\n/g, '\\n')}'; this.closest('#ai-preview-result').classList.add('hidden');">
              Appliquer cette proposition
            </button>
          </div>
        `
        resultContainer.classList.remove('hidden')
      } else {
        resultContainer.innerHTML = `
          <div class="text-red-600 text-sm">
            Erreur : ${data.errors?.join(', ') || 'Impossible de générer la preview'}
          </div>
        `
        resultContainer.classList.remove('hidden')
      }
    } catch (error) {
      resultContainer.innerHTML = `
        <div class="text-red-600 text-sm">
          Erreur lors de la génération : ${error.message}
        </div>
      `
      resultContainer.classList.remove('hidden')
    } finally {
      // Réactiver le bouton
      button.disabled = false
      button.innerHTML = `
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z"></path>
        </svg>
        Générer avec l'IA
      `
    }
  }
}

