import { Controller } from "@hotwired/stimulus"

// Gère les actions du bloc image principale sur la fiche produit :
//   - share() : ouvre le partage natif (Web Share API) si dispo, sinon copie
//     l'URL dans le presse-papiers avec toast visuel
//   - zoom() / close() : ouvre / ferme une lightbox plein écran avec l'image
//     principale actuelle. Fermable via clic backdrop, bouton close ou Esc.
//
// Markup attendu (dans items/show.html.erb) :
//   <div data-controller="product-image-actions"
//        data-product-image-actions-title-value="Nom produit"
//        data-product-image-actions-url-value="https://…">
//     <img id="main-product-image" src="…">
//     <button data-action="click->product-image-actions#share">…</button>
//     <button data-action="click->product-image-actions#zoom">…</button>
//   </div>
export default class extends Controller {
  static values = {
    title: String,
    url:   String,
    mainImageSelector: { type: String, default: "#main-product-image" }
  }

  async share(event) {
    event.preventDefault()
    const url = this.urlValue || window.location.href
    const title = this.titleValue || document.title

    if (navigator.share) {
      try {
        await navigator.share({ title, text: title, url })
        return
      } catch (err) {
        if (err?.name === "AbortError") return
      }
    }

    try {
      await navigator.clipboard.writeText(url)
      this._toast("Lien copié dans le presse-papiers")
    } catch {
      this._toast("Impossible de copier le lien")
    }
  }

  zoom(event) {
    event.preventDefault()
    const img = document.querySelector(this.mainImageSelectorValue)
    if (!img) return

    const overlay = document.createElement("div")
    overlay.className = "fixed inset-0 z-[9999] flex items-center justify-center bg-black/85 p-4 cursor-zoom-out"
    overlay.setAttribute("role", "dialog")
    overlay.setAttribute("aria-modal", "true")
    overlay.setAttribute("aria-label", "Aperçu de l'image")

    const zoomed = document.createElement("img")
    zoomed.src = img.currentSrc || img.src
    zoomed.alt = img.alt || ""
    zoomed.className = "max-w-full max-h-full object-contain shadow-2xl select-none"
    zoomed.addEventListener("click", (e) => e.stopPropagation())

    const close = document.createElement("button")
    close.type = "button"
    close.setAttribute("aria-label", "Fermer")
    close.className = "absolute top-4 right-4 w-10 h-10 bg-white/95 hover:bg-white rounded-full flex items-center justify-center shadow-lg"
    close.innerHTML = '<svg class="w-5 h-5 text-gray-800" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/></svg>'

    const closeHandler = () => this._closeLightbox(overlay)
    overlay.addEventListener("click", closeHandler)
    close.addEventListener("click", (e) => { e.stopPropagation(); closeHandler() })

    this._escHandler = (e) => { if (e.key === "Escape") closeHandler() }
    document.addEventListener("keydown", this._escHandler)

    overlay.appendChild(zoomed)
    overlay.appendChild(close)
    document.body.appendChild(overlay)
    document.body.style.overflow = "hidden"
  }

  _closeLightbox(overlay) {
    overlay.remove()
    document.body.style.overflow = ""
    if (this._escHandler) {
      document.removeEventListener("keydown", this._escHandler)
      this._escHandler = null
    }
  }

  _toast(message) {
    const toast = document.createElement("div")
    toast.textContent = message
    toast.className = "fixed top-4 left-1/2 -translate-x-1/2 z-[10000] bg-gray-900 text-white text-sm font-medium px-4 py-2 rounded-lg shadow-lg opacity-0 transition-opacity duration-200"
    document.body.appendChild(toast)
    requestAnimationFrame(() => { toast.style.opacity = "1" })
    setTimeout(() => {
      toast.style.opacity = "0"
      setTimeout(() => toast.remove(), 220)
    }, 2000)
  }

  disconnect() {
    if (this._escHandler) {
      document.removeEventListener("keydown", this._escHandler)
      this._escHandler = null
    }
    document.body.style.overflow = ""
  }
}
