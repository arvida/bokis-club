import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "icon", "text", "button", "input"]
  static values = { hideText: String }

  toggle() {
    const isHidden = this.contentTarget.classList.contains("hidden")

    if (isHidden) {
      this.show()
    } else {
      this.hide()
    }
  }

  show() {
    this.contentTarget.classList.remove("hidden")

    if (this.hasButtonTarget) {
      this.buttonTarget.setAttribute("aria-expanded", "true")
    }

    if (this.hasIconTarget) {
      this.iconTarget.classList.add("rotate-180")
    }

    if (this.hasTextTarget && this.hasHideTextValue) {
      this.textTarget.textContent = this.hideTextValue
    }
  }

  hide() {
    this.contentTarget.classList.add("hidden")

    if (this.hasButtonTarget) {
      this.buttonTarget.setAttribute("aria-expanded", "false")
      // Restore original show text from data attribute
      const showText = this.buttonTarget.dataset.repliesShowTextValue
      if (this.hasTextTarget && showText) {
        this.textTarget.textContent = showText
      }
    }

    if (this.hasIconTarget) {
      this.iconTarget.classList.remove("rotate-180")
    }
  }

  showForm() {
    this.contentTarget.classList.remove("hidden")

    if (this.hasButtonTarget) {
      this.buttonTarget.setAttribute("aria-expanded", "true")
    }

    const input = this.contentTarget.querySelector("textarea")
    if (input) {
      input.focus()
    }
  }

  clearForm(event) {
    if (event.detail.success && this.hasInputTarget) {
      this.inputTarget.value = ""
      this.inputTarget.style.height = "auto"
    }
  }
}
