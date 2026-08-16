import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["slotSelect", "deliveryFee", "finalTotal"]

  static values = { 
    currencySymbol: String,
    cartTotal: Number,
    initialDeliveryFee: Number
  }

  initialize() {
    this.slotValid = false
  }

  connect() {
    // Si une zone est déjà sélectionnée au chargement, initialiser les frais de livraison
    if (this.hasInitialDeliveryFeeValue && this.initialDeliveryFeeValue > 0) {
      this.updateDeliveryFee(this.initialDeliveryFeeValue)
    }
    
    const zoneSelect = document.getElementById("zone-select")
    const checkedZoneRadio = document.querySelector('input[name="delivery_zone_id"]:checked')
    const initialZoneId = zoneSelect?.value || checkedZoneRadio?.value || ""
    const preselectedSlotId = this.slotSelectTarget.dataset.selectedSlotId || ""
    
    // Vérifier si le select de slot existe déjà et a une valeur
    const slotSelect = document.getElementById("delivery-slot-select")
    if (slotSelect && slotSelect.value) {
      this.slotSelectTarget.dataset.selectedSlotId = slotSelect.value
      this.setSlotValid(true)
      return
    }

    if (initialZoneId) {
      this.updateZoneCards(initialZoneId)
      this.updateZoneSummary(initialZoneId)
      this.loadSlotsForZone(initialZoneId, preselectedSlotId)
    } else {
      this.setSlotValid(Boolean(preselectedSlotId))
    }

    if (preselectedSlotId) {
      this.setSlotValid(true)
    }
  }

  async loadSlots(event) {
    const zoneId = event.target.value
    this.updateZoneCards(zoneId)
    await this.loadSlotsForZone(zoneId)
  }

  async zoneSelected(event) {
    const zoneId = event.target.value
    const zoneSelect = document.getElementById("zone-select")
    if (zoneSelect) zoneSelect.value = zoneId
    this.updateZoneCards(zoneId)
    this.updateZoneSummary(zoneId)
    this.closeZoneModal()
    await this.loadSlotsForZone(zoneId)
  }

  openZoneModal() {
    const modal = document.getElementById('delivery-zone-modal')
    if (modal) modal.classList.remove('hidden')
  }

  closeZoneModal() {
    const modal = document.getElementById('delivery-zone-modal')
    if (modal) modal.classList.add('hidden')
  }

  stopPropagation(event) {
    event.stopPropagation()
  }

  async loadSlotsForZone(zoneId, preselectedSlotId = "") {
    if (!zoneId) {
      this.displayNoSlots()
      this.updateDeliveryFee(0)
      this.setSlotValid(false)
      return
    }

    this.slotSelectTarget.innerHTML = '<label class="block text-sm sm:text-base font-semibold text-gray-900 mb-4 flex items-center gap-2"><svg class="w-5 h-5 text-[#551694]" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg><span>Créneau de livraison</span></label><div class="p-6 bg-gray-50 border-2 border-gray-200 rounded-xl text-center"><div class="flex items-center justify-center gap-3"><svg class="animate-spin h-5 w-5 text-[#551694]" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path></svg><p class="text-sm text-gray-600 font-medium">Chargement des créneaux...</p></div></div>'
    this.slotSelectTarget.dataset.selectedSlotId = preselectedSlotId
    this.setSlotValid(false)

    try {
      const response = await fetch(`/client/orders/get_delivery_slots?delivery_zone_id=${zoneId}`, {
        headers: {
          "Accept": "application/json",
          "X-Requested-With": "XMLHttpRequest"
        }
      })

      const data = await response.json()

      if (data.slots && data.slots.length > 0) {
        const selectedId = preselectedSlotId || ""
        this.displaySlots(data.slots, selectedId)
        this.updateDeliveryFee(data.base_fee)
      } else {
        this.displayNoSlots("Aucun créneau disponible pour cette zone")
        this.updateDeliveryFee(0)
        this.setSlotValid(false)
      }
    } catch (error) {
      console.error("Erreur lors du chargement des créneaux:", error)
      this.displayNoSlots("Erreur lors du chargement des créneaux")
      this.updateDeliveryFee(0)
      this.setSlotValid(false)
    }
  }

  displaySlots(slots, selectedSlotId = "") {
    let html = '<label class="block text-sm sm:text-base font-semibold text-gray-900 mb-4 flex items-center gap-2">'
    html += '<svg class="w-5 h-5 text-[#551694]" fill="none" stroke="currentColor" viewBox="0 0 24 24">'
    html += '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path>'
    html += '</svg>'
    html += '<span>Créneau de livraison</span>'
    html += '</label>'
    html += '<div class="grid grid-cols-2 gap-3" id="delivery-slots-container">'

    slots.forEach((slot) => {
      const isSelected = slot.id.toString() === selectedSlotId.toString()
      const borderClass = isSelected ? 'border-[#551694] bg-[#551694]/5 shadow-sm' : 'border-gray-200 bg-white'
      const gradientClass = isSelected ? 'from-[#551694] to-[#6a1fa8]' : 'from-gray-100 to-gray-200 group-hover:from-[#551694]/20 group-hover:to-[#6a1fa8]/20'
      const iconClass = isSelected ? 'text-white' : 'text-gray-400 group-hover:text-[#551694]'
      const checkedAttr = isSelected ? 'checked' : ''
      
      html += `<label class="flex items-center gap-3 p-4 border-2 rounded-xl cursor-pointer transition-all hover:border-[#551694] hover:shadow-md group ${borderClass}">`
      html += `<input type="radio" name="delivery_slot_id" value="${slot.id}" ${checkedAttr} class="w-5 h-5 text-[#551694] focus:ring-[#551694] focus:ring-2 border-gray-300 cursor-pointer transition-all" required data-action="change->order#slotSelected">`
      html += '<div class="flex-1 flex items-center justify-between">'
      html += '<div class="flex items-center gap-3">'
      html += `<div class="w-10 h-10 bg-gradient-to-br ${gradientClass} rounded-lg flex items-center justify-center transition-all shadow-sm">`
      html += `<svg class="w-5 h-5 ${iconClass} transition-colors" fill="none" stroke="currentColor" viewBox="0 0 24 24">`
      html += '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path>'
      html += '</svg>'
      html += '</div>'
      html += '<div>'
      html += `<p class="font-semibold text-sm sm:text-base text-gray-900">${slot.time_range}</p>`
      html += '<p class="text-xs text-gray-500 mt-0.5">Disponible pour la livraison</p>'
      html += '</div>'
      html += '</div>'
      if (isSelected) {
        html += '<div class="flex-shrink-0">'
        html += '<svg class="w-6 h-6 text-[#551694]" fill="none" stroke="currentColor" viewBox="0 0 24 24">'
        html += '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>'
        html += '</svg>'
        html += '</div>'
      }
      html += '</div>'
      html += '</label>'
    })

    html += "</div>"

    this.slotSelectTarget.innerHTML = html
    this.slotSelectTarget.dataset.selectedSlotId = selectedSlotId
    this.setSlotValid(Boolean(selectedSlotId))
  }

  displayNoSlots(message = "Sélectionnez une zone de livraison pour voir les créneaux disponibles") {
    let html = '<label class="block text-sm sm:text-base font-semibold text-gray-900 mb-4 flex items-center gap-2">'
    html += '<svg class="w-5 h-5 text-[#551694]" fill="none" stroke="currentColor" viewBox="0 0 24 24">'
    html += '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path>'
    html += '</svg>'
    html += '<span>Créneau de livraison</span>'
    html += '</label>'
    html += '<div class="p-6 bg-gray-50 border-2 border-gray-200 rounded-xl text-center">'
    html += '<svg class="w-12 h-12 text-gray-300 mx-auto mb-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">'
    html += '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path>'
    html += '</svg>'
    html += `<p class="text-sm text-gray-500 font-medium">${message}</p>`
    html += '<p class="text-xs text-gray-400 mt-1">Sélectionnez d\'abord une zone de livraison</p>'
    html += '</div>'
    this.slotSelectTarget.innerHTML = html
    this.slotSelectTarget.dataset.selectedSlotId = ""
    this.setSlotValid(false)
  }

  slotSelected(event) {
    const slotId = event.target.value
    this.slotSelectTarget.dataset.selectedSlotId = slotId
    
    // Mettre à jour l'UI pour refléter la sélection
    const container = document.getElementById('delivery-slots-container')
    if (container) {
      const labels = container.querySelectorAll('label')
      labels.forEach((label) => {
        const radio = label.querySelector('input[type="radio"]')
        const isSelected = radio && radio.value === slotId
        
        if (isSelected) {
          label.classList.remove('border-gray-200', 'bg-white')
          label.classList.add('border-[#551694]', 'bg-[#551694]/5', 'shadow-sm')
          
          // Ajouter l'icône de check
          let checkIcon = label.querySelector('.check-icon')
          if (!checkIcon) {
            checkIcon = document.createElement('div')
            checkIcon.className = 'flex-shrink-0 check-icon'
            checkIcon.innerHTML = '<svg class="w-6 h-6 text-[#551694]" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path></svg>'
            const flexDiv = label.querySelector('.flex-1')
            if (flexDiv) {
              flexDiv.appendChild(checkIcon)
            }
          }
          
          // Mettre à jour le gradient de l'icône
          const iconContainer = label.querySelector('.w-10.h-10')
          if (iconContainer) {
            iconContainer.classList.remove('from-gray-100', 'to-gray-200', 'group-hover:from-[#551694]/20', 'group-hover:to-[#6a1fa8]/20')
            iconContainer.classList.add('from-[#551694]', 'to-[#6a1fa8]')
          }
          
          // Mettre à jour la couleur de l'icône SVG
          const iconSvg = label.querySelector('.w-10.h-10 svg')
          if (iconSvg) {
            iconSvg.classList.remove('text-gray-400', 'group-hover:text-[#551694]')
            iconSvg.classList.add('text-white')
          }
        } else {
          label.classList.remove('border-[#551694]', 'bg-[#551694]/5', 'shadow-sm')
          label.classList.add('border-gray-200', 'bg-white')
          
          // Retirer l'icône de check
          const checkIcon = label.querySelector('.check-icon')
          if (checkIcon) {
            checkIcon.remove()
          }
          
          // Remettre le gradient par défaut
          const iconContainer = label.querySelector('.w-10.h-10')
          if (iconContainer) {
            iconContainer.classList.remove('from-[#551694]', 'to-[#6a1fa8]')
            iconContainer.classList.add('from-gray-100', 'to-gray-200', 'group-hover:from-[#551694]/20', 'group-hover:to-[#6a1fa8]/20')
          }
          
          // Remettre la couleur par défaut de l'icône SVG
          const iconSvg = label.querySelector('.w-10.h-10 svg')
          if (iconSvg) {
            iconSvg.classList.remove('text-white')
            iconSvg.classList.add('text-gray-400', 'group-hover:text-[#551694]')
          }
        }
      })
    }
    
    this.setSlotValid(Boolean(slotId))
  }

  updateZoneCards(zoneId) {
    const container = document.getElementById('delivery-zones-container')
    if (!container) return

    const cards = container.querySelectorAll('.zone-card')
    cards.forEach((card) => {
      const cardZoneId = card.dataset.zoneId
      const isSelected = cardZoneId === zoneId?.toString()

      card.classList.toggle('border-[#551694]', isSelected)
      card.classList.toggle('bg-[#551694]/5', isSelected)
      card.classList.toggle('shadow-sm', isSelected)
      card.classList.toggle('border-gray-200', !isSelected)
      card.classList.toggle('bg-white', !isSelected)

      const checkIcon = card.querySelector('.zone-check')
      if (checkIcon) checkIcon.classList.toggle('hidden', !isSelected)

      const radio = card.querySelector('input[name="delivery_zone_id"]')
      if (radio) radio.checked = isSelected
    })
  }

  updateZoneSummary(zoneId) {
    const container = document.getElementById('delivery-zones-container')
    if (!container) return

    const selectedCard = container.querySelector(`.zone-card[data-zone-id="${zoneId}"]`)
    if (!selectedCard) return

    const nameEl = document.getElementById('selected-zone-name')
    const descriptionEl = document.getElementById('selected-zone-description')
    const feeEl = document.getElementById('selected-zone-fee')

    if (nameEl) nameEl.textContent = selectedCard.dataset.zoneName || ''
    if (descriptionEl) {
      const cardDescription = selectedCard.querySelector('.zone-description')
      descriptionEl.innerHTML = cardDescription ? cardDescription.innerHTML : (selectedCard.dataset.zoneDescription || '')
    }
    if (feeEl) feeEl.textContent = selectedCard.dataset.zoneFee || '—'
  }

  setSlotValid(valid) {
    this.slotValid = valid
    // Émettre l'événement avec les détails pour que payment_method_controller puisse réagir
    document.dispatchEvent(new CustomEvent("checkout:slot-valid", { 
      detail: { valid: valid } 
    }))
  }

  updateDeliveryFee(baseFee) {
    const fee = Number(baseFee) || 0
    if (this.hasDeliveryFeeTarget) {
      this.deliveryFeeTarget.textContent = this.formatCurrency(fee)
    }
    if (this.hasFinalTotalTarget) {
      const total = Number(this.cartTotalValue) + fee
      this.finalTotalTarget.textContent = this.formatCurrency(total)
    }
  }

  formatCurrency(amount) {
    return new Intl.NumberFormat("fr-FR", {
      style: "currency",
      currency: "XOF",
      minimumFractionDigits: 0,
      maximumFractionDigits: 0
    }).format(amount).replace("XOF", this.currencySymbolValue)
  }
}

