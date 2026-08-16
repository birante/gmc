import { Controller } from "@hotwired/stimulus"

// Synchronise un <input type="color"> et un <input type="text"> qui partagent la même valeur hex.
export default class extends Controller {
  static targets = ["picker", "hex"]

  syncFromPicker() {
    if (!this.hasHexTarget) return
    this.hexTarget.value = this.pickerTarget.value.toUpperCase()
  }

  syncFromHex() {
    if (!this.hasPickerTarget) return
    const value = (this.hexTarget.value || "").trim()
    if (/^#?[0-9a-fA-F]{6}$/.test(value)) {
      const normalized = value.startsWith("#") ? value : `#${value}`
      this.pickerTarget.value = normalized.toLowerCase()
    }
  }
}
