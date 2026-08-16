import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]

  toggle() {
    this.menuTarget.classList.toggle("hidden")
    
    // Empêcher le scroll du body quand le menu est ouvert
    if (this.menuTarget.classList.contains("hidden")) {
      document.body.style.overflow = ""
    } else {
      document.body.style.overflow = "hidden"
    }
  }
}

