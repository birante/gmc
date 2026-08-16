import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "button"]

  copy() {
    // Copier le lien dans le presse-papiers
    const link = this.inputTarget.value
    
    navigator.clipboard.writeText(link).then(() => {
      // Afficher le message de succès
      const originalText = this.buttonTarget.textContent
      this.buttonTarget.textContent = "✓ Copié!"
      this.buttonTarget.classList.add("bg-green-600")
      this.buttonTarget.classList.remove("bg-blue-600")
      
      // Revenir à l'état initial après 2 secondes
      setTimeout(() => {
        this.buttonTarget.textContent = originalText
        this.buttonTarget.classList.remove("bg-green-600")
        this.buttonTarget.classList.add("bg-blue-600")
      }, 2000)
    }).catch(() => {
      // En cas d'erreur
      this.buttonTarget.textContent = "✗ Erreur"
      this.buttonTarget.classList.add("bg-red-600")
      this.buttonTarget.classList.remove("bg-blue-600")
      
      setTimeout(() => {
        this.buttonTarget.textContent = "Copier"
        this.buttonTarget.classList.remove("bg-red-600")
        this.buttonTarget.classList.add("bg-blue-600")
      }, 2000)
    })
  }
}
