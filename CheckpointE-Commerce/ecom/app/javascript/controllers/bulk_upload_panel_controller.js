import { Controller } from "@hotwired/stimulus"

// Panneau slide-in pour l'import CSV en masse de produits.
// S'ouvre via un évènement custom `bulk-upload-panel:open` ou via Esc / clic
// sur l'overlay pour fermer. Modèle calqué sur product_sheet_controller.
export default class extends Controller {
  static targets = ["sheet", "overlay", "fileInput", "submit", "fileName"]

  connect() {
    this.handleOpen = () => this.open()
    this.handleKeydown = (e) => {
      if (e.key === "Escape" && !this.sheetTarget.classList.contains("translate-x-full")) {
        this.close()
      }
    }
    this.handleTransitionEnd = (e) => {
      if (e.target === this.sheetTarget && this.sheetTarget.classList.contains("translate-x-full")) {
        this.sheetTarget.classList.add("hidden")
        this.sheetTarget.classList.remove("flex", "flex-col")
      }
    }

    document.addEventListener("bulk-upload-panel:open", this.handleOpen)
    document.addEventListener("keydown", this.handleKeydown)
    this.sheetTarget.addEventListener("transitionend", this.handleTransitionEnd)
    this.overlayTarget.addEventListener("click", () => this.close())
  }

  disconnect() {
    document.removeEventListener("bulk-upload-panel:open", this.handleOpen)
    document.removeEventListener("keydown", this.handleKeydown)
    this.sheetTarget.removeEventListener("transitionend", this.handleTransitionEnd)
  }

  open() {
    this.sheetTarget.classList.remove("hidden")
    this.sheetTarget.classList.add("flex", "flex-col")
    this.overlayTarget.classList.remove("hidden")
    requestAnimationFrame(() => this.sheetTarget.classList.remove("translate-x-full"))
    document.body.style.overflow = "hidden"
  }

  close() {
    this.sheetTarget.classList.add("translate-x-full")
    this.overlayTarget.classList.add("hidden")
    document.body.style.overflow = ""
  }

  // Affiche le nom du fichier choisi et active le bouton submit.
  fileChanged() {
    const file = this.fileInputTarget.files[0]
    if (file) {
      if (this.hasFileNameTarget) this.fileNameTarget.textContent = file.name
      if (this.hasSubmitTarget) this.submitTarget.disabled = false
    } else {
      if (this.hasFileNameTarget) this.fileNameTarget.textContent = ""
      if (this.hasSubmitTarget) this.submitTarget.disabled = true
    }
  }
}
