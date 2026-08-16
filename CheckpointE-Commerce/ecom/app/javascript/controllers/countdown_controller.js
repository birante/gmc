import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["days", "hours", "minutes", "seconds"]
  static values = {
    endDate: String
  }

  connect() {
    // If no end date provided, default to 24 hours from now
    if (!this.endDateValue) {
      const tomorrow = new Date()
      tomorrow.setHours(tomorrow.getHours() + 24)
      this.endDateValue = tomorrow.toISOString()
    }

    this.endTime = new Date(this.endDateValue).getTime()
    this.updateCountdown()
    this.interval = setInterval(() => this.updateCountdown(), 1000)
  }

  disconnect() {
    if (this.interval) {
      clearInterval(this.interval)
    }
  }

  updateCountdown() {
    const now = new Date().getTime()
    const distance = this.endTime - now

    if (distance < 0) {
      // Countdown finished
      this.setTime(0, 0, 0, 0)
      clearInterval(this.interval)
      return
    }

    const days = Math.floor(distance / (1000 * 60 * 60 * 24))
    const hours = Math.floor((distance % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60))
    const minutes = Math.floor((distance % (1000 * 60 * 60)) / (1000 * 60))
    const seconds = Math.floor((distance % (1000 * 60)) / 1000)

    this.setTime(days, hours, minutes, seconds)
  }

  setTime(days, hours, minutes, seconds) {
    if (this.hasDaysTarget) {
      this.daysTarget.textContent = this.padNumber(days)
    }
    if (this.hasHoursTarget) {
      this.hoursTarget.textContent = this.padNumber(hours)
    }
    if (this.hasMinutesTarget) {
      this.minutesTarget.textContent = this.padNumber(minutes)
    }
    if (this.hasSecondsTarget) {
      this.secondsTarget.textContent = this.padNumber(seconds)
    }
  }

  padNumber(num) {
    return num.toString().padStart(2, '0')
  }
}

