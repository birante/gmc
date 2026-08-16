import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]

  connect() {
    // Focus sur le premier champ au chargement
    if (this.inputTargets.length > 0) {
      this.inputTargets[0].focus()
    }
  }

  // Gérer la saisie dans chaque champ
  handleInput(event) {
    const currentInput = event.target
    const currentIndex = this.inputTargets.indexOf(currentInput)

    // Ne garder que les chiffres
    const value = currentInput.value.replace(/\D/g, "")
    
    if (value.length > 0) {
      currentInput.value = value[0]
      
      // Passer au champ suivant si ce n'est pas le dernier
      if (currentIndex < this.inputTargets.length - 1) {
        this.inputTargets[currentIndex + 1].focus()
      }
    } else {
      currentInput.value = ""
    }
  }

  // Gérer la touche Backspace
  handleKeydown(event) {
    const currentInput = event.target
    const currentIndex = this.inputTargets.indexOf(currentInput)

    // Si Backspace et champ vide, revenir au champ précédent
    if (event.key === "Backspace" && currentInput.value === "" && currentIndex > 0) {
      this.inputTargets[currentIndex - 1].focus()
      this.inputTargets[currentIndex - 1].value = ""
    }
  }

  // Gérer le collage (paste)
  handlePaste(event) {
    event.preventDefault()
    const pasteData = event.clipboardData.getData("text").replace(/\D/g, "").slice(0, 4)
    
    pasteData.split("").forEach((char, index) => {
      if (this.inputTargets[index]) {
        this.inputTargets[index].value = char
      }
    })
    
    // Focus sur le dernier champ rempli
    const lastIndex = Math.min(pasteData.length - 1, this.inputTargets.length - 1)
    if (lastIndex >= 0) {
      this.inputTargets[lastIndex].focus()
    }
  }
}
