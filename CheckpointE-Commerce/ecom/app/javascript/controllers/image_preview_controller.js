import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="image-preview"
export default class extends Controller {
  static targets = ["input", "previewContainer", "previewTemplate"]

  connect() {
    // Controller connecté
    this.imageFiles = []
  }

  previewMain(event) {
    const file = event.target.files[0]
    if (!file) return

    const reader = new FileReader()
    reader.onload = (e) => {
      const preview = document.getElementById('main-image-preview')
      const previewImg = document.getElementById('main-image-preview-img')
      
      if (preview && previewImg) {
        previewImg.src = e.target.result
        preview.classList.remove('hidden')
      } else if (preview) {
        // Si l'image n'existe pas encore, créer l'élément
        const img = document.createElement('img')
        img.id = 'main-image-preview-img'
        img.src = e.target.result
        img.className = 'w-32 h-32 object-cover rounded-lg border border-gray-200'
        img.alt = 'Preview'
        preview.appendChild(img)
        preview.classList.remove('hidden')
      }
    }
    reader.readAsDataURL(file)
  }

  previewAdditional(event) {
    const files = Array.from(event.target.files)
    const container = document.getElementById('additional-images-preview')
    
    if (!container) {
      // Créer le container s'il n'existe pas
      const imagesSection = document.getElementById('additional-images-container')
      if (imagesSection) {
        const newContainer = document.createElement('div')
        newContainer.id = 'additional-images-preview'
        newContainer.className = 'grid grid-cols-3 gap-2 mb-2'
        imagesSection.appendChild(newContainer)
      }
    }
    
    const previewContainer = document.getElementById('additional-images-preview')
    if (!previewContainer) return

    files.forEach((file, index) => {
      const reader = new FileReader()
      reader.onload = (e) => {
        const div = document.createElement('div')
        div.className = 'relative'
        div.innerHTML = `
          <img src="${e.target.result}" alt="Preview ${index + 1}" class="w-full h-20 object-cover rounded border border-gray-200">
          <button type="button" class="absolute top-1 right-1 bg-red-500 text-white rounded-full p-1 hover:bg-red-600 text-xs" onclick="this.parentElement.remove(); removeFileFromInput(${index})">
            ×
          </button>
        `
        previewContainer.appendChild(div)
      }
      reader.readAsDataURL(file)
    })
  }

  handleFiles(event) {
    const files = Array.from(event.target.files).slice(0, 5) // Max 5 images
    if (!files.length) return

    this.imageFiles = files
    this.updatePreview()
  }

  updatePreview() {
    if (!this.hasPreviewContainerTarget || !this.hasPreviewTemplateTarget) return

    this.previewContainerTarget.innerHTML = ''
    
    if (this.imageFiles.length === 0) {
      this.previewContainerTarget.classList.add('hidden')
      return
    }

    this.previewContainerTarget.classList.remove('hidden')

    this.imageFiles.forEach((file, index) => {
      const reader = new FileReader()
      reader.onload = (e) => {
        const clone = this.previewTemplateTarget.content.cloneNode(true)
        const container = clone.querySelector('.relative')
        const img = clone.querySelector('img')
        const removeBtn = clone.querySelector('button')
        
        if (container) {
          container.dataset.index = index
        }
        
        if (img) {
          img.src = e.target.result
          img.dataset.index = index
        }
        
        if (removeBtn) {
          removeBtn.dataset.index = index
        }

        this.previewContainerTarget.appendChild(clone)
      }
      reader.readAsDataURL(file)
    })
  }

  removeImage(event) {
    const button = event.currentTarget
    const container = button.closest('.relative')
    const img = container.querySelector('img')
    const index = parseInt(img.dataset.index || container.dataset.index || '0')
    
    this.imageFiles.splice(index, 1)
    container.remove()
    this.updateFileInput()
    
    if (this.imageFiles.length === 0) {
      this.previewContainerTarget.classList.add('hidden')
    }
  }

  updateFileInput() {
    if (!this.hasInputTarget) return
    
    const dataTransfer = new DataTransfer()
    this.imageFiles.forEach(file => dataTransfer.items.add(file))
    this.inputTarget.files = dataTransfer.files
  }
}
