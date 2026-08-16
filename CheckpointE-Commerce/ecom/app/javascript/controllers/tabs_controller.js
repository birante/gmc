import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]
  
  connect() {
    // Afficher le premier onglet par défaut
    this.showTab(0)
  }
  
  select(event) {
    event.preventDefault()
    const index = parseInt(event.currentTarget.dataset.index)
    this.showTab(index)
  }
  
  showTab(index) {
    // Gérer les classes des onglets
    this.tabTargets.forEach((tab, i) => {
      if (i === index) {
        // Onglet actif
        tab.classList.remove('border-transparent', 'text-gray-500')
        tab.classList.add('border-[#551694]', 'text-gray-900')
      } else {
        // Onglet inactif
        tab.classList.remove('border-[#551694]', 'text-gray-900')
        tab.classList.add('border-transparent', 'text-gray-500')
      }
    })
    
    // Afficher/masquer les panels correspondants
    this.panelTargets.forEach((panel, i) => {
      if (i === index) {
        panel.classList.remove('hidden')
      } else {
        panel.classList.add('hidden')
      }
    })
  }
}

