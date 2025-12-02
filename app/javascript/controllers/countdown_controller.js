import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    deadline: String,
    expiredText: { type: String, default: "Tiden har gått ut" }
  }
  static targets = ["display"]

  connect() {
    this.updateCountdown()
    this.timer = setInterval(() => this.updateCountdown(), 1000)
  }

  disconnect() {
    if (this.timer) {
      clearInterval(this.timer)
    }
  }

  updateCountdown() {
    const deadline = new Date(this.deadlineValue)
    const now = new Date()
    const diff = deadline - now

    if (diff <= 0) {
      this.displayTarget.textContent = this.expiredTextValue
      clearInterval(this.timer)
      return
    }

    const days = Math.floor(diff / (1000 * 60 * 60 * 24))
    const hours = Math.floor((diff % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60))
    const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60))
    const seconds = Math.floor((diff % (1000 * 60)) / 1000)

    if (days > 0) {
      this.displayTarget.textContent = `${days}d ${hours}h`
    } else if (hours > 0) {
      this.displayTarget.textContent = `${hours}h ${minutes}m`
    } else {
      this.displayTarget.textContent = `${minutes}m ${seconds}s`
    }
  }
}
