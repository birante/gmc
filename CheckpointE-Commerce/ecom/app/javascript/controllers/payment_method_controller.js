import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["section", "submitButton", "placeholder"]
  static values = {
    selected: String
  }

  initialize() {
    this.updateBound = this.update.bind(this)
  }

  connect() {
    // Initialiser selectedValue depuis l'attribut data ou depuis le radio button sélectionné
    if (!this.hasSelectedValue || !this.selectedValueValue) {
      const selectedRadio = this.element.querySelector('input[type="radio"][name="payment_method_id"]:checked')
      this.selectedValue = selectedRadio ? selectedRadio.value : ""
    }

    document.addEventListener("checkout:slot-valid", this.updateBound)
    // Attendre un peu pour que le DOM soit complètement chargé
    setTimeout(() => this.update(), 100)
  }

  disconnect() {
    document.removeEventListener("checkout:slot-valid", this.updateBound)
  }

  select(event) {
    this.selectedValue = event.target.value
    this.update()
  }

  update() {
    // Vérifier à nouveau le radio button sélectionné au cas où il aurait changé
    const selectedRadio = this.element.querySelector('input[type="radio"][name="payment_method_id"]:checked')
    const selected = selectedRadio ? selectedRadio.value : (this.selectedValue || "")
    const slotValid = this.slotIsSelected()

    this.sectionTargets.forEach((section) => {
      const shouldShow = section.dataset.methodId === selected
      section.classList.toggle("hidden", !shouldShow)
      section.querySelectorAll("input, select, textarea").forEach((field) => {
        field.disabled = !shouldShow
      })
    })

    if (this.hasPlaceholderTarget) {
      this.placeholderTarget.classList.toggle("hidden", selected.length > 0)
    }

    if (this.hasSubmitButtonTarget) {
      const button = this.submitButtonTarget
      const isEnabled = selected.length > 0 && slotValid

      button.disabled = !isEnabled
      // S'assurer que les classes CSS sont correctement appliquées
      if (isEnabled) {
        button.classList.remove("opacity-50", "bg-gray-400", "cursor-not-allowed")
        button.classList.add("bg-[#551694]", "hover:bg-[#6a1fa8]")
      } else {
        button.classList.add("opacity-50", "bg-gray-400", "cursor-not-allowed")
        button.classList.remove("bg-[#551694]", "hover:bg-[#6a1fa8]")
      }
    }
  }

  slotIsSelected() {
    const slotSelect = document.getElementById("delivery-slot-select")
    if (!slotSelect) return false
    
    // Vérifier si le select a une valeur valide
    const hasValue = slotSelect.value && slotSelect.value.length > 0 && slotSelect.value !== ""
    
    // Vérifier aussi dans le dataset de l'order controller
    const orderController = document.querySelector('[data-controller*="order"]')
    if (orderController) {
      const slotSelectElement = orderController.querySelector('[data-order-target="slotSelect"]')
      if (slotSelectElement) {
        const selectedSlotId = slotSelectElement.dataset.selectedSlotId
        if (selectedSlotId && selectedSlotId.length > 0) {
          return true
        }
      }
    }
    
    return hasValue
  }

  get selectedValue() {
    return this.selectedValueValue
  }

  set selectedValue(value) {
    this.selectedValueValue = value
  }
}
