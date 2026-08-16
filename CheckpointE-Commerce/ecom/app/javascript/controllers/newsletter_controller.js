import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["email", "submitBtn", "btnText", "successMsg", "errorMsg", "successText", "errorText"]

  async submit(e) {
    e.preventDefault()
    
    const email = this.emailTarget.value.trim()
    
    if (!email) {
      this.showError("Veuillez entrer une adresse email")
      return
    }
    
    // Disable button and show loading state
    this.submitBtnTarget.disabled = true
    this.btnTextTarget.textContent = "Inscription..."
    
    // Clear messages
    this.hideMessages()
    
    try {
      const response = await fetch(this.element.querySelector("form").action, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('[name="csrf-token"]').content
        },
        body: JSON.stringify({ email })
      })
      
      const data = await response.json()
      
      if (data.success) {
        this.showSuccess(data.message)
        this.emailTarget.value = ""
      } else {
        this.showError(data.message)
      }
    } catch (error) {
      console.error("Newsletter error:", error)
      this.showError("Une erreur est survenue. Veuillez réessayer.")
    } finally {
      // Re-enable button and hide loading state
      this.submitBtnTarget.disabled = false
      this.btnTextTarget.textContent = "S'abonner"
    }
  }
  
  showSuccess(message) {
    this.successTextTarget.textContent = message
    this.successMsgTarget.classList.remove("hidden")
    this.errorMsgTarget.classList.add("hidden")
  }
  
  showError(message) {
    this.errorTextTarget.textContent = message
    this.errorMsgTarget.classList.remove("hidden")
    this.successMsgTarget.classList.add("hidden")
  }
  
  hideMessages() {
    this.successMsgTarget.classList.add("hidden")
    this.errorMsgTarget.classList.add("hidden")
  }
}
