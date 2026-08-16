import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["search", "list", "selectedContainer", "empty", "count", "dropdown"]
  static values = {
    sectors: Array,
    selectedIds: Array
  }

  connect() {
    this.filteredSectors = this.sectorsValue
    this.selectedSectorIds = new Set(this.selectedIdsValue || [])
    // Afficher tous les secteurs au chargement
    this.renderDropdown()
    this.updateSelectedCount()
    this.closeDropdown()
  }

  search() {
    const query = this.searchTarget.value.toLowerCase().trim()
    
    if (query.length === 0) {
      // Afficher tous les secteurs si la recherche est vide
      this.filteredSectors = this.sectorsValue
    } else {
      // Filtrer les secteurs qui correspondent à la recherche
      this.filteredSectors = this.sectorsValue.filter(sector =>
        sector.name.toLowerCase().includes(query)
      )
    }
    
    // Toujours afficher la liste
    this.renderDropdown()
    this.openDropdown()
  }

  toggleSector(event) {
    event.preventDefault()
    event.stopPropagation()
    
    const sectorId = parseInt(event.currentTarget.dataset.sectorId)
    const sectorName = event.currentTarget.dataset.sectorName
    const checkbox = event.currentTarget.querySelector('input[type="checkbox"]')
    
    // Inverser l'état de la checkbox
    checkbox.checked = !checkbox.checked
    
    if (checkbox.checked) {
      this.addSector(sectorId, sectorName)
    } else {
      this.removeSector(sectorId)
    }
    
    // Mettre à jour le rendu du dropdown pour refléter l'état actuel
    // sans refiltrer (garder la même recherche)
    this.renderDropdown()
    this.openDropdown()
  }

  removeSectorTag(event) {
    event.stopPropagation()
    const sectorId = parseInt(event.currentTarget.dataset.sectorId)
    this.removeSector(sectorId)
    
    // Mettre à jour le rendu de la liste pour refléter le changement
    this.renderDropdown()
  }

  openDropdown() {
    if (!this.hasDropdownTarget) return
    this.dropdownTarget.classList.remove('hidden')
  }

  closeDropdown() {
    if (!this.hasDropdownTarget) return
    this.dropdownTarget.classList.add('hidden')
  }

  handleClickOutside(event) {
    if (this.element.contains(event.target)) return
    this.closeDropdown()
  }

  addSector(sectorId, sectorName) {
    if (this.selectedSectorIds.has(sectorId)) return
    
    this.selectedSectorIds.add(sectorId)
    this.createSectorTag(sectorId, sectorName)
    this.updateContainerVisibility()
    this.updateHiddenInputs()
    this.updateSelectedCount()
  }

  removeSector(sectorId) {
    if (!this.selectedSectorIds.has(sectorId)) return
    
    this.selectedSectorIds.delete(sectorId)
    
    // Retirer le tag
    const tag = this.selectedContainerTarget.querySelector(`[data-tag-sector-id="${sectorId}"]`)
    if (tag) {
      tag.remove()
    }
    
    // Retirer l'input hidden
    const hiddenInput = document.getElementById(`sector_${sectorId}`)
    if (hiddenInput) {
      hiddenInput.remove()
    }
    
    this.updateContainerVisibility()
    this.updateHiddenInputs()
    this.updateSelectedCount()
  }

  createSectorTag(sectorId, sectorName) {
    // Vérifier si le tag existe déjà
    if (this.selectedContainerTarget.querySelector(`[data-tag-sector-id="${sectorId}"]`)) {
      return
    }

    const tag = document.createElement('span')
    tag.className = 'inline-flex items-center px-3 py-1 rounded-full text-sm bg-[#551694] text-white'
    tag.setAttribute('data-tag-sector-id', sectorId)
    
    const textNode = document.createTextNode(sectorName)
    tag.appendChild(textNode)
    
    const removeBtn = document.createElement('button')
    removeBtn.type = 'button'
    removeBtn.className = 'ml-2 text-white hover:text-gray-200 focus:outline-none transition-colors'
    removeBtn.setAttribute('data-action', 'click->sector-selector#removeSectorTag')
    removeBtn.setAttribute('data-sector-id', sectorId)
    removeBtn.innerHTML = '×'
    tag.appendChild(removeBtn)

    // Créer l'input hidden
    const hiddenInput = document.createElement('input')
    hiddenInput.type = 'hidden'
    hiddenInput.name = 'shop[sector_ids][]'
    hiddenInput.value = sectorId
    hiddenInput.id = `sector_${sectorId}`
    tag.appendChild(hiddenInput)

    this.selectedContainerTarget.appendChild(tag)
  }

  updateHiddenInputs() {
    // Cette méthode peut être utilisée pour synchroniser les inputs cachés si nécessaire
  }

  updateContainerVisibility() {
    // Afficher ou masquer le container selon qu'il y a des secteurs sélectionnés
    if (this.selectedSectorIds.size > 0) {
      this.selectedContainerTarget.classList.remove('hidden')
    } else {
      this.selectedContainerTarget.classList.add('hidden')
    }
  }

  updateSelectedCount() {
    if (!this.hasCountTarget) return
    this.countTarget.textContent = `${this.selectedSectorIds.size} sélectionné(s)`
  }

  renderDropdown() {
    if (!this.hasListTarget) return
    
    if (this.filteredSectors.length === 0) {
      this.listTarget.innerHTML = ''
      this.showEmptyMessage()
      return
    }
    
    this.hideEmptyMessage()
    this.listTarget.innerHTML = this.filteredSectors.map(sector => {
      const isSelected = this.selectedSectorIds.has(sector.id)
      return `
        <div
          data-action="click->sector-selector#toggleSector"
          data-sector-id="${sector.id}"
          data-sector-name="${sector.name}"
          class="flex items-center min-w-0 px-3 py-2 hover:bg-purple-50 cursor-pointer transition-colors border-b border-gray-100 last:border-b-0 ${isSelected ? 'bg-purple-50' : ''}"
        >
          <input
            type="checkbox"
            id="sector_checkbox_${sector.id}"
            ${isSelected ? 'checked' : ''}
            style="accent-color: #551694;"
            class="w-5 h-5 shrink-0 rounded border-gray-300 text-[#551694] focus:ring-[#551694] cursor-pointer mr-3"
            readonly
          />
          <label for="sector_checkbox_${sector.id}" class="text-sm font-medium text-gray-700 cursor-pointer flex-1 min-w-0 truncate">
            ${sector.name}
          </label>
        </div>
      `
    }).join('')
  }

  showEmptyMessage() {
    if (this.hasEmptyTarget) {
      this.emptyTarget.classList.remove('hidden')
    }
  }

  hideEmptyMessage() {
    if (this.hasEmptyTarget) {
      this.emptyTarget.classList.add('hidden')
    }
  }
}

