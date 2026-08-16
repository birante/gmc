import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["star", "ratingInput", "ratingText"]

  static values = {
    selected: { type: Number, default: 0 }
  }

  static labels = {
    1: "Très mauvais",
    2: "Mauvais",
    3: "Moyen",
    4: "Bien",
    5: "Excellent"
  }

  connect() {
    this._paint(this.selectedValue)
  }

  selectRating(event) {
    const rating = parseInt(event.currentTarget.dataset.rating, 10)
    this.selectedValue = rating
    if (this.hasRatingInputTarget) this.ratingInputTarget.value = rating
    this._paint(rating)
    this._setText(rating)
  }

  hoverStar(event) {
    if (this.selectedValue > 0) return
    const rating = parseInt(event.currentTarget.dataset.rating, 10)
    this._paint(rating)
  }

  resetStars() {
    this._paint(this.selectedValue)
  }

  _paint(count) {
    this.starTargets.forEach((star, idx) => {
      const svg = star.querySelector("svg")
      if (!svg) return
      if (idx < count) {
        svg.classList.remove("text-gray-300")
        svg.classList.add("text-yellow-400")
      } else {
        svg.classList.remove("text-yellow-400")
        svg.classList.add("text-gray-300")
      }
    })
  }

  _setText(rating) {
    if (!this.hasRatingTextTarget) return
    const labels = this.constructor.labels || {}
    this.ratingTextTarget.textContent = labels[rating] || ""
  }
}
