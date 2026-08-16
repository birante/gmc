import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "attributesContainer",
    "variantsMatrix",
    "generateButton",
    "attributeTemplate",
    "valueTemplate",
    "variantRowTemplate",
    "combinationsInfo",
    "matrixContainer",
    "attributesData",
    "shopColorsData"
  ]

  static values = {
    itemId: String,
    newColorUrl: String
  }

  connect() {
    this.attributeIndex = 0
    this.valueIndex = 0
    this.variantIndex = 0

    if (this.hasAttributesDataTarget) {
      try {
        this.productAttributes = JSON.parse(this.attributesDataTarget.textContent)
      } catch (e) {
        console.error("Erreur lors du chargement des attributs:", e)
        this.productAttributes = []
      }
    } else {
      this.productAttributes = []
    }

    if (this.hasShopColorsDataTarget) {
      try {
        this.shopColors = JSON.parse(this.shopColorsDataTarget.textContent)
      } catch (e) {
        this.shopColors = []
      }
    } else {
      this.shopColors = []
    }
  }

  isColorAttributeName(name) {
    if (!name) return false
    const n = name.toLowerCase().trim()
    return n === "couleur" || n === "color" || n === "colour" || n.includes("couleur")
  }
  
  // Gérer le changement d'attribut dans le select
  handleAttributeChange(event) {
    console.log('🔄 handleAttributeChange appelé')
    const select = event.target
    const selectedAttributeId = select.selectedOptions[0]?.dataset.attributeId
    const selectedAttributeName = select.value
    
    console.log('Attribut sélectionné:', selectedAttributeName, 'ID:', selectedAttributeId)
    
    if (!selectedAttributeName || !selectedAttributeId) {
      console.log('⚠️ Pas de nom ou ID d\'attribut')
      return
    }
    
    console.log('Attributs disponibles:', this.productAttributes)
    
    // Trouver l'attribut sélectionné dans les données
    const attribute = this.productAttributes.find(attr => attr.id.toString() === selectedAttributeId)
    
    console.log('Attribut trouvé:', attribute)
    
    if (!attribute) {
      console.error('❌ Attribut non trouvé avec l\'ID:', selectedAttributeId)
      return
    }
    
    // Trouver le container de valeurs
    const attributeContainer = select.closest('[data-attribute-container]')
    const valuesContainer = attributeContainer.querySelector('[data-values-container]')
    const attributeIndexValue = attributeContainer.dataset.attributeId

    if (this.isColorAttributeName(selectedAttributeName)) {
      this.renderShopColorSwatches(valuesContainer, attributeIndexValue)
    } else {
      this.renderAttributeValueCheckboxes(valuesContainer, attributeIndexValue, attribute)
    }

    this.updateGenerateButton()
  }

  renderAttributeValueCheckboxes(valuesContainer, attributeIndexValue, attribute) {
    const values = attribute.product_attribute_values || []
    const normalize = (str) => (str || '').toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '')

    const items = values.map((value, index) => `
      <label data-filterable-item data-filter-key="${this.escapeHtml(normalize(value.value))}"
             class="flex items-center gap-2 p-2 hover:bg-gray-50 rounded cursor-pointer">
        <input type="checkbox"
               name="item[item_attributes_attributes][${attributeIndexValue}][attribute_values_attributes][${index}][value]"
               value="${this.escapeHtml(value.value)}"
               data-action="change->variant-manager#handleInputChange"
               class="w-4 h-4 text-purple-600 border-gray-300 rounded focus:ring-purple-500" />
        <input type="hidden"
               name="item[item_attributes_attributes][${attributeIndexValue}][attribute_values_attributes][${index}][_destroy]"
               value="0" />
        <span class="text-sm text-gray-900">${this.escapeHtml(value.value)}</span>
      </label>
    `).join('')

    const attrLabel = (attribute.name || 'valeur').toLowerCase()
    const searchBar = values.length > 6 ? this.buildValueSearchBar(`Rechercher une ${this.escapeHtml(attrLabel)}...`) : ''

    valuesContainer.innerHTML = `
      ${searchBar}
      <div>${items}</div>
      <p data-filter-no-results class="hidden text-xs text-gray-500 italic mt-2">Aucune valeur ne correspond à votre recherche.</p>
    `
  }

  buildValueSearchBar(placeholder) {
    return `
      <div class="relative mb-2">
        <svg class="absolute left-2 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-4.35-4.35M17 10a7 7 0 11-14 0 7 7 0 0114 0z"/>
        </svg>
        <input type="search"
               placeholder="${placeholder}"
               data-action="input->variant-manager#filterAttributeValues"
               class="block w-full pl-8 pr-3 py-1.5 text-sm border border-gray-300 rounded-md focus:ring-purple-500 focus:border-purple-500" />
      </div>
    `
  }

  renderShopColorSwatches(valuesContainer, attributeIndexValue) {
    const paletteUrl = this.hasNewColorUrlValue ? this.newColorUrlValue : "#"

    if (!this.shopColors || this.shopColors.length === 0) {
      valuesContainer.innerHTML = `
        <div class="p-3 border border-dashed border-gray-300 rounded text-sm text-gray-600 space-y-2">
          <p>Votre palette est vide. Ajoutez d'abord des couleurs dans <strong>Mes couleurs</strong>, puis revenez ici.</p>
          <a href="${this.escapeHtml(paletteUrl)}" target="_blank" rel="noopener"
             class="inline-flex items-center gap-1 text-[#551694] hover:underline">
            + Ouvrir ma palette
            <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14 5l7 7m0 0l-7 7m7-7H3"/>
            </svg>
          </a>
        </div>
      `
      return
    }

    const normalize = (str) => (str || '').toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '')

    const swatches = this.shopColors.map((color, index) => `
      <label data-filterable-item data-filter-key="${this.escapeHtml(normalize(color.name))}"
             class="flex items-center gap-2 p-2 hover:bg-gray-50 rounded cursor-pointer border border-gray-100">
        <input type="checkbox"
               name="item[item_attributes_attributes][${attributeIndexValue}][attribute_values_attributes][${index}][value]"
               value="${this.escapeHtml(color.name)}"
               data-action="change->variant-manager#handleInputChange"
               class="w-4 h-4 text-purple-600 border-gray-300 rounded focus:ring-purple-500" />
        <input type="hidden"
               name="item[item_attributes_attributes][${attributeIndexValue}][attribute_values_attributes][${index}][hex_code]"
               value="${this.escapeHtml(color.hex_code)}" />
        <input type="hidden"
               name="item[item_attributes_attributes][${attributeIndexValue}][attribute_values_attributes][${index}][shop_color_id]"
               value="${color.id}" />
        <input type="hidden"
               name="item[item_attributes_attributes][${attributeIndexValue}][attribute_values_attributes][${index}][_destroy]"
               value="0" />
        <span class="inline-block w-5 h-5 rounded-full border border-gray-300 flex-shrink-0"
              style="background-color: ${this.escapeHtml(color.hex_code)};"></span>
        <span class="text-sm text-gray-900">${this.escapeHtml(color.name)}</span>
      </label>
    `).join('')

    const searchBar = this.shopColors.length > 6 ? this.buildValueSearchBar('Rechercher une couleur...') : ''

    valuesContainer.innerHTML = `
      ${searchBar}
      <div class="grid grid-cols-1 sm:grid-cols-2 gap-1">${swatches}</div>
      <p data-filter-no-results class="hidden text-xs text-gray-500 italic mt-2">Aucune couleur ne correspond à votre recherche.</p>
      <div class="mt-3 pt-3 border-t border-gray-100 text-xs text-gray-600">
        <a href="${this.escapeHtml(paletteUrl)}" target="_blank" rel="noopener"
           class="inline-flex items-center gap-1 text-[#551694] hover:underline">
          + Ajouter une couleur à ma palette
        </a>
      </div>
    `
  }

  filterAttributeValues(event) {
    const searchInput = event.target
    const container = searchInput.closest('[data-values-container]')
    if (!container) return

    const raw = searchInput.value.trim()
    const query = raw.toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '')
    const items = container.querySelectorAll('[data-filterable-item]')
    let visibleCount = 0

    items.forEach((label) => {
      const key = label.dataset.filterKey || ''
      const matches = query === '' || key.includes(query)
      label.classList.toggle('hidden', !matches)
      if (matches) visibleCount++
    })

    const noResults = container.querySelector('[data-filter-no-results]')
    if (noResults) noResults.classList.toggle('hidden', visibleCount > 0)
  }

  // Ajouter un nouvel attribut
  addAttribute() {
    const template = this.attributeTemplateTarget.content.cloneNode(true)
    const container = template.querySelector('[data-attribute-container]')

    // Rails strong params n'accepte que des clés numériques pour les nested
    // attributes en format hash. On utilise un entier basé sur Date.now() +
    // index pour garantir l'unicité et éviter toute collision avec les IDs
    // existants en base.
    const uniqueId = `${Date.now()}${this.attributeIndex}`

    const html = container.innerHTML.replace(/NEW_ATTRIBUTE/g, uniqueId)
    container.innerHTML = html
    container.dataset.attributeId = uniqueId

    this.attributesContainerTarget.appendChild(container)
    this.attributeIndex++

    this.updateGenerateButton()
  }

  // Supprimer un attribut
  removeAttribute(event) {
    const attributeContainer = event.target.closest('[data-attribute-container]')
    
    // Si l'attribut existe déjà en DB, marquer pour destruction
    const destroyField = attributeContainer.querySelector('input[name*="[_destroy]"]')
    if (destroyField) {
      destroyField.value = '1'
      attributeContainer.style.display = 'none'
    } else {
      attributeContainer.remove()
    }
    
    this.updateGenerateButton()
  }

  // Ajouter une valeur à un attribut
  addValue(event) {
    const attributeContainer = event.target.closest('[data-attribute-container]')
    const valuesContainer = attributeContainer.querySelector('[data-values-container]')
    const attributeId = attributeContainer.dataset.attributeId
    
    const template = this.valueTemplateTarget.content.cloneNode(true)
    const valueDiv = template.querySelector('[data-value-item]')
    
    // Rails strong params n'accepte que des clés numériques pour les nested attributes
    const uniqueValueId = `${Date.now()}${this.valueIndex}`
    const html = valueDiv.innerHTML
      .replace(/ATTRIBUTE_INDEX/g, attributeId)
      .replace(/NEW_VALUE/g, uniqueValueId)
    valueDiv.innerHTML = html
    
    valuesContainer.appendChild(valueDiv)
    this.valueIndex++
    
    this.updateGenerateButton()
  }

  // Supprimer une valeur
  removeValue(event) {
    const valueItem = event.target.closest('[data-value-item]')
    
    // Si la valeur existe déjà en DB, marquer pour destruction
    const destroyField = valueItem.querySelector('input[name*="[_destroy]"]')
    if (destroyField) {
      destroyField.value = '1'
      valueItem.style.display = 'none'
    } else {
      valueItem.remove()
    }
    
    this.updateGenerateButton()
  }

  // Générer les combinaisons de variantes
  generateCombinations() {
    // Collecter tous les attributs et leurs valeurs
    const attributes = this.collectAttributes()
    
    if (attributes.length === 0) {
      alert("Veuillez ajouter au moins un attribut avec des valeurs")
      return
    }

    // Générer le produit cartésien
    const combinations = this.cartesianProduct(attributes)
    
    // Afficher les combinaisons
    this.displayCombinations(combinations, attributes)
    
    // Afficher le nombre de combinaisons
    if (this.hasCombinationsInfoTarget) {
      this.combinationsInfoTarget.textContent = `${combinations.length} combinaison(s) générée(s)`
    }
    
    // Afficher la matrice
    if (this.hasMatrixContainerTarget) {
      this.matrixContainerTarget.classList.remove('hidden')
    }
  }

  // Collecter les attributs et valeurs depuis le DOM
  collectAttributes() {
    const attributes = []
    const attributeContainers = this.attributesContainerTarget.querySelectorAll('[data-attribute-container]')
    
    attributeContainers.forEach((container) => {
      // Ignorer les attributs marqués pour destruction
      const destroyField = container.querySelector('input[name*="[_destroy]"]')
      if (destroyField && destroyField.value === '1') return
      if (container.style.display === 'none') return
      
      // Récupérer le nom de l'attribut (soit depuis un select, soit depuis un input)
      const nameSelect = container.querySelector('select[name*="[name]"]')
      const nameInput = container.querySelector('input[name*="[name]"]')
      const attributeName = nameSelect ? nameSelect.value : (nameInput ? nameInput.value : '')
      
      // Récupérer les valeurs cochées (avec hex si disponible pour les swatches couleur)
      const checkedCheckboxes = container.querySelectorAll('input[type="checkbox"][name*="[value]"]:checked')

      const values = []
      checkedCheckboxes.forEach((checkbox) => {
        const label = checkbox.closest('label')
        const hexInput = label ? label.querySelector('input[name*="[hex_code]"]') : null
        const raw = checkbox.value.trim()
        if (!raw) return
        values.push(hexInput && hexInput.value ? { value: raw, hex_code: hexInput.value } : raw)
      })

      if (attributeName.trim() && values.length > 0) {
        attributes.push({
          name: attributeName.trim(),
          values: values
        })
      }
    })
    
    return attributes
  }

  // Générer le produit cartésien (toutes les combinaisons)
  cartesianProduct(attributes) {
    const normalize = (name, v) => (typeof v === 'string' ? { name, value: v } : { name, value: v.value, hex_code: v.hex_code })

    if (attributes.length === 0) return []
    if (attributes.length === 1) {
      return attributes[0].values.map(v => [normalize(attributes[0].name, v)])
    }

    const result = []
    const helper = (current, index) => {
      if (index === attributes.length) {
        result.push([...current])
        return
      }

      const attr = attributes[index]
      attr.values.forEach(value => {
        helper([...current, normalize(attr.name, value)], index + 1)
      })
    }

    helper([], 0)
    return result
  }

  // Afficher les combinaisons dans la matrice
  displayCombinations(combinations, attributes) {
    // Vider la matrice existante
    const tbody = this.variantsMatrixTarget.querySelector('tbody')
    tbody.innerHTML = ''
    
    // Recréer l'en-tête avec les colonnes d'attributs
    const thead = this.variantsMatrixTarget.querySelector('thead tr')
    // Garder seulement les colonnes fixes (actif, prix, stock, SKU)
    const fixedHeaders = ['<th class="px-4 py-3 text-left text-xs font-medium text-gray-700 uppercase tracking-wider bg-gray-100">Actif</th>']
    
    // Ajouter les colonnes d'attributs
    attributes.forEach(attr => {
      fixedHeaders.push(`<th class="px-4 py-3 text-left text-xs font-medium text-gray-700 uppercase tracking-wider">${this.escapeHtml(attr.name)}</th>`)
    })
    
    fixedHeaders.push(
      '<th class="px-4 py-3 text-left text-xs font-medium text-gray-700 uppercase tracking-wider">Prix (modifier)</th>',
      '<th class="px-4 py-3 text-left text-xs font-medium text-gray-700 uppercase tracking-wider">Stock</th>',
      '<th class="px-4 py-3 text-left text-xs font-medium text-gray-700 uppercase tracking-wider">SKU</th>'
    )
    
    thead.innerHTML = fixedHeaders.join('')
    
    // Créer une ligne pour chaque combinaison
    combinations.forEach((combination, index) => {
      const row = this.createVariantRow(combination, index)
      tbody.appendChild(row)
    })
  }

  // Créer une ligne de variante
  createVariantRow(combination, index) {
    const tr = document.createElement('tr')
    tr.className = 'border-b hover:bg-gray-50'
    tr.dataset.variantIndex = index
    
    // Générer le SKU automatiquement
    const skuParts = combination.map(c => c.value.toUpperCase().replace(/\s+/g, '-'))
    const sku = `${this.itemIdValue || 'NEW'}-${skuParts.join('-')}`
    
    // Construire les colonnes
    let cells = ''
    
    // Colonne Actif (checkbox pour _destroy inversé)
    cells += `
      <td class="px-4 py-3">
        <input type="checkbox" 
               checked
               data-variant-active-checkbox
               data-action="change->variant-manager#toggleVariantActive"
               class="w-4 h-4 text-purple-600 rounded focus:ring-purple-500" />
        <input type="hidden" 
               name="item[variants_attributes][${this.variantIndex}][_destroy]" 
               value="0" 
               data-destroy-field />
      </td>
    `
    
    // Colonnes des attributs (lecture seule, avec hidden fields pour stocker les données)
    combination.forEach((attr) => {
      const swatch = attr.hex_code
        ? `<span class="inline-block w-4 h-4 rounded-full border border-gray-300 align-middle mr-2" style="background-color: ${this.escapeHtml(attr.hex_code)};"></span>`
        : ''
      cells += `
        <td class="px-4 py-3 text-sm text-gray-900">
          ${swatch}${this.escapeHtml(attr.value)}
          <input type="hidden"
                 name="item[variants_attributes][${this.variantIndex}][combination_data][]"
                 value="${this.escapeHtml(JSON.stringify(attr))}" />
        </td>
      `
    })
    
    // Prix (éditable, par défaut hérite du prix du produit)
    cells += `
      <td class="px-4 py-3">
        <input type="number" 
               name="item[variants_attributes][${this.variantIndex}][price]" 
               step="0.01"
               min="0"
               placeholder="0"
               class="w-full px-2 py-1 text-sm border border-gray-300 rounded focus:ring-purple-500 focus:border-purple-500" />
      </td>
    `
    
    // Stock (éditable)
    cells += `
      <td class="px-4 py-3">
        <input type="number" 
               name="item[variants_attributes][${this.variantIndex}][stock_quantity]" 
               min="0"
               value="0"
               class="w-full px-2 py-1 text-sm border border-gray-300 rounded focus:ring-purple-500 focus:border-purple-500" />
      </td>
    `
    
    // SKU (auto-généré, éditable)
    cells += `
      <td class="px-4 py-3">
        <input type="text" 
               name="item[variants_attributes][${this.variantIndex}][sku]" 
               value="${sku}"
               readonly
               class="w-full px-2 py-1 text-sm border border-gray-200 rounded bg-gray-50 text-gray-600" />
      </td>
    `
    
    // Hidden fields pour is_default
    cells += `
      <input type="hidden" 
             name="item[variants_attributes][${this.variantIndex}][is_default]" 
             value="false" />
    `
    
    tr.innerHTML = cells
    this.variantIndex++
    
    return tr
  }

  // Mettre à jour le bouton de génération
  updateGenerateButton() {
    const attributes = this.collectAttributes()
    const hasAttributes = attributes.length > 0
    
    if (this.hasGenerateButtonTarget) {
      this.generateButtonTarget.disabled = !hasAttributes
      if (hasAttributes) {
        const count = this.cartesianProduct(attributes).length
        this.generateButtonTarget.textContent = `Générer ${count} combinaison(s)`
      } else {
        this.generateButtonTarget.textContent = 'Générer les combinaisons'
      }
    }
  }

  // Utilitaire pour échapper le HTML
  escapeHtml(text) {
    const map = {
      '&': '&amp;',
      '<': '&lt;',
      '>': '&gt;',
      '"': '&quot;',
      "'": '&#039;'
    }
    return text.replace(/[&<>"']/g, m => map[m])
  }
  
  // Écouter les changements dans les inputs pour mettre à jour le bouton
  handleInputChange() {
    this.updateGenerateButton()
  }
  
  // Toggle l'état actif d'une variante (en inversant _destroy)
  toggleVariantActive(event) {
    const checkbox = event.target
    const row = checkbox.closest('tr')
    const destroyField = row.querySelector('input[data-destroy-field]')
    
    if (destroyField) {
      // Si la case est décochée, marquer pour destruction
      destroyField.value = checkbox.checked ? '0' : '1'
      
      // Ajuster le style visuel
      if (!checkbox.checked) {
        row.style.opacity = '0.5'
        row.style.backgroundColor = '#fee'
      } else {
        row.style.opacity = '1'
        row.style.backgroundColor = ''
      }
    }
  }
}
