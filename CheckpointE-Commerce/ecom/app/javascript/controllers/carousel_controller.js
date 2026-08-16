import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["slide", "dot", "slidesContainer", "liveRegion", "playPauseButton", "pauseIcon", "playIcon", "prevButton", "nextButton"]
  static values = {
    autoplay: { type: Boolean, default: true },
    interval: { type: Number, default: 5000 },
    currentIndex: { type: Number, default: 0 }
  }

  connect() {
    this.currentIndexValue = 0
    this.isPlaying = this.autoplayValue
    this.updateSlides()
    
    if (this.autoplayValue) {
      this.startAutoplay()
    }

    // Keyboard navigation
    this.element.addEventListener("keydown", this.handleKeydown.bind(this))
    
    // Pause on hover/focus for accessibility
    this.element.addEventListener("mouseenter", this.pause.bind(this))
    this.element.addEventListener("mouseleave", this.resume.bind(this))
    this.element.addEventListener("focusin", this.pause.bind(this))
    this.element.addEventListener("focusout", this.handleFocusOut.bind(this))
  }

  disconnect() {
    this.stopAutoplay()
    this.element.removeEventListener("keydown", this.handleKeydown.bind(this))
    this.element.removeEventListener("mouseenter", this.pause.bind(this))
    this.element.removeEventListener("mouseleave", this.resume.bind(this))
    this.element.removeEventListener("focusin", this.pause.bind(this))
    this.element.removeEventListener("focusout", this.handleFocusOut.bind(this))
  }

  // Keyboard navigation handler
  handleKeydown(event) {
    switch (event.key) {
      case "ArrowLeft":
        event.preventDefault()
        this.previous()
        break
      case "ArrowRight":
        event.preventDefault()
        this.next()
        break
      case "Home":
        event.preventDefault()
        this.goTo(0)
        break
      case "End":
        event.preventDefault()
        this.goTo(this.slideTargets.length - 1)
        break
      case " ":
      case "Enter":
        // Si le focus est sur un dot, ne pas interférer
        if (event.target.hasAttribute("data-index")) {
          return
        }
        event.preventDefault()
        this.toggleAutoplay()
        break
    }
  }

  handleFocusOut(event) {
    // Reprendre l'autoplay seulement si le focus quitte complètement le carousel
    if (!this.element.contains(event.relatedTarget) && this.isPlaying) {
      this.startAutoplay()
    }
  }

  next() {
    const nextIndex = (this.currentIndexValue + 1) % this.slideTargets.length
    this.goTo(nextIndex)
  }

  previous() {
    const prevIndex = (this.currentIndexValue - 1 + this.slideTargets.length) % this.slideTargets.length
    this.goTo(prevIndex)
  }

  goToSlide(event) {
    const index = parseInt(event.currentTarget.dataset.index, 10)
    this.goTo(index)
  }

  goTo(index) {
    this.currentIndexValue = index
    this.updateSlides()
    this.announceSlide()
    
    // Reset autoplay timer when manually navigating
    if (this.isPlaying) {
      this.stopAutoplay()
      this.startAutoplay()
    }
  }

  updateSlides() {
    this.slideTargets.forEach((slide, index) => {
      const isActive = index === this.currentIndexValue
      
      // Opacity transition
      slide.classList.toggle("opacity-0", !isActive)
      slide.classList.toggle("opacity-100", isActive)
      
      // Accessibility attributes
      slide.setAttribute("aria-hidden", !isActive)
      slide.setAttribute("tabindex", isActive ? "0" : "-1")
    })

    // Update dots (tabs)
    if (this.hasDotTarget) {
      this.dotTargets.forEach((dot, index) => {
        const isActive = index === this.currentIndexValue
        
        // Visual state
        dot.classList.toggle("bg-white", !isActive)
        dot.classList.toggle("bg-gray-900", isActive)
        
        // Accessibility: aria-selected for tabs
        dot.setAttribute("aria-selected", isActive)
      })
    }
  }

  // Announce slide change to screen readers
  announceSlide() {
    if (this.hasLiveRegionTarget) {
      const total = this.slideTargets.length
      const current = this.currentIndexValue + 1
      this.liveRegionTarget.textContent = `Slide ${current} sur ${total}`
    }
  }

  // Toggle autoplay on/off
  toggleAutoplay() {
    if (this.isPlaying) {
      this.stopAutoplay()
      this.isPlaying = false
      this.updatePlayPauseButton(false)
    } else {
      this.startAutoplay()
      this.isPlaying = true
      this.updatePlayPauseButton(true)
    }
  }

  updatePlayPauseButton(isPlaying) {
    if (this.hasPlayPauseButtonTarget) {
      const label = isPlaying 
        ? "Mettre en pause le défilement automatique" 
        : "Reprendre le défilement automatique"
      this.playPauseButtonTarget.setAttribute("aria-label", label)
      
      if (this.hasPauseIconTarget && this.hasPlayIconTarget) {
        this.pauseIconTarget.classList.toggle("hidden", !isPlaying)
        this.playIconTarget.classList.toggle("hidden", isPlaying)
      }
    }
  }

  startAutoplay() {
    this.stopAutoplay() // Clear any existing timer
    this.autoplayTimer = setInterval(() => {
      this.next()
    }, this.intervalValue)
  }

  stopAutoplay() {
    if (this.autoplayTimer) {
      clearInterval(this.autoplayTimer)
      this.autoplayTimer = null
    }
  }

  // Pause on hover/focus
  pause() {
    this.stopAutoplay()
  }

  resume() {
    if (this.isPlaying) {
      this.startAutoplay()
    }
  }
}
