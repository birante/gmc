import { Controller } from "@hotwired/stimulus"

// Copie une URL dans le presse-papiers et affiche brièvement "Copié !"
// dans un target `label` (préserve l'icône SVG voisine).
//
// Markup attendu :
//   <div data-controller="share-link" data-share-link-url-value="...">
//     <button type="button" data-action="click->share-link#copy">
//       <svg>…</svg>
//       <span data-share-link-target="label">Copier le lien</span>
//     </button>
//   </div>
export default class extends Controller {
  static targets = ["label"]
  static values = {
    url: String,
    feedbackText: { type: String, default: "✓ Copié !" },
    feedbackDuration: { type: Number, default: 2000 }
  }

  async copy() {
    if (!this.urlValue) return

    try {
      await navigator.clipboard.writeText(this.urlValue)
      this._flashFeedback(this.feedbackTextValue)
    } catch (err) {
      console.error("[share-link] copy failed", err)
      this._flashFeedback("✗ Erreur")
    }
  }

  _flashFeedback(text) {
    if (!this.hasLabelTarget) return
    const original = this.labelTarget.textContent
    this.labelTarget.textContent = text
    clearTimeout(this._timer)
    this._timer = setTimeout(() => {
      this.labelTarget.textContent = original
    }, this.feedbackDurationValue)
  }
}
