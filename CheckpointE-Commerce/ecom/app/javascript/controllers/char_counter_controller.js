import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="char-counter"
export default class extends Controller {
  static targets = ["counter", "textarea"]
  static values = { max: Number }

  connect() {
    this.updateCounter()
  }

  updateCounter() {
    const textarea = this.hasTextareaTarget ? this.textareaTarget : this.element.querySelector('textarea')
    if (!textarea) return

    const length = textarea.value.length
    const max = this.hasMaxValue ? this.maxValue : 2000
    const counter = this.hasCounterTarget ? this.counterTarget : null

    if (counter) {
      counter.textContent = `${length} / ${max}`
      if (length > max * 0.9) {
        counter.classList.remove('text-gray-400')
        counter.classList.add('text-orange-500')
      } else {
        counter.classList.remove('text-orange-500')
        counter.classList.add('text-gray-400')
      }
    }
  }
}
