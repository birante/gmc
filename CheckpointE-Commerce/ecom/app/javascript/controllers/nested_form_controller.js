import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["item", "template"]
  static values = {
    wrapper: String
  }

  connect() {
    // Initialiser le compteur pour les nouveaux enregistrements
    this.newRecordIndex = this.getMaxIndex() + 1
  }

  add(event) {
    event.preventDefault()
    
    const template = this.templateTarget.content.cloneNode(true)
    const newItem = template.querySelector('[data-nested-form-target="item"]')
    
    if (!newItem) return

    // Remplacer NEW_RECORD par un index numérique dans tous les attributs name, id, et for
    this.replacePlaceholders(newItem, 'NEW_RECORD', this.newRecordIndex)
    
    // Insérer avant le bouton "Ajouter"
    const addButton = event.currentTarget
    const container = addButton.parentElement
    container.insertBefore(newItem, addButton)
    
    this.newRecordIndex++
  }

  remove(event) {
    event.preventDefault()
    
    const item = event.currentTarget.closest('[data-nested-form-target="item"]')
    if (!item) return

    // Trouver le champ _destroy et le marquer
    const destroyInput = item.querySelector('[data-nested-form-target="destroyInput"]')
    if (destroyInput) {
      // Si c'est un enregistrement existant, marquer pour destruction
      if (destroyInput.closest('[data-nested-form-target="item"]').querySelector('input[type="hidden"][name$="[id]"]')?.value) {
        destroyInput.value = '1'
        item.style.display = 'none'
      } else {
        // Sinon, supprimer complètement l'élément
        item.remove()
      }
    } else {
      // Fallback: supprimer directement si pas de champ _destroy
      item.remove()
    }
  }

  replacePlaceholders(element, placeholder, index) {
    // Remplacer dans les noms de champs et IDs
    element.querySelectorAll('input, select, textarea').forEach(input => {
      if (input.name) {
        input.name = input.name.replace(new RegExp(placeholder, 'g'), index)
      }
      if (input.id) {
        input.id = input.id.replace(new RegExp(placeholder, 'g'), index)
      }
    })

    // Remplacer dans les labels
    element.querySelectorAll('label').forEach(label => {
      const forAttr = label.getAttribute('for')
      if (forAttr) {
        label.setAttribute('for', forAttr.replace(new RegExp(placeholder, 'g'), index))
      }
    })
  }

  getMaxIndex() {
    let maxIndex = -1
    this.itemTargets.forEach(item => {
      const idInput = item.querySelector('input[type="hidden"][name$="[id]"]')
      if (!idInput || !idInput.value) {
        // C'est un nouveau record, extraire l'index du nom
        const nameInput = item.querySelector('input[name*="["]')
        if (nameInput) {
          const match = nameInput.name.match(/\[(\d+)\]/)
          if (match) {
            const index = parseInt(match[1])
            if (index > maxIndex) maxIndex = index
          }
        }
      }
    })
    return maxIndex
  }
}
