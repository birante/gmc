import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["mainImage", "thumbnail"]

  select(event) {
    const thumb = event.currentTarget
    const detailUrl = thumb.dataset.detailUrl
    if (!detailUrl || !this.hasMainImageTarget) return

    this.mainImageTarget.src = detailUrl
    this.mainImageTarget.alt = thumb.querySelector("img")?.alt || ""

    this.thumbnailTargets.forEach((t) => {
      const isActive = t === thumb
      t.classList.toggle("border-[#551694]", isActive)
      t.classList.toggle("ring-1", isActive)
      t.classList.toggle("ring-[#551694]/20", isActive)
      t.classList.toggle("border-gray-200", !isActive)
      t.classList.toggle("hover:border-gray-300", !isActive)
    })
  }
}
