import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "sheet", "textarea"]

  connect() {
    this.closeOnEscape = this.closeOnEscape.bind(this)
  }

  open() {
    if (this.hasModalTarget) {
      this.modalTarget.classList.remove("hidden")
      // Trigger reflow, then animate sheet up
      requestAnimationFrame(() => {
        if (this.hasSheetTarget) {
          this.sheetTarget.classList.remove("translate-y-full")
        }
      })
    }
    document.addEventListener("keydown", this.closeOnEscape)
    document.body.style.overflow = "hidden"

    if (this.hasTextareaTarget) {
      setTimeout(() => this.textareaTarget.focus(), 100)
    }
  }

  close() {
    // Slide sheet down first
    if (this.hasSheetTarget) {
      this.sheetTarget.classList.add("translate-y-full")
    }

    // Wait for animation to complete before hiding modal
    setTimeout(() => {
      if (this.hasModalTarget) {
        this.modalTarget.classList.add("hidden")
      }

      if (this.hasTextareaTarget) {
        this.textareaTarget.value = ""
        this.textareaTarget.style.height = "auto"
      }
    }, 300)

    document.removeEventListener("keydown", this.closeOnEscape)
    document.body.style.overflow = ""
  }

  closeOnEscape(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }

  autoResize() {
    if (this.hasTextareaTarget) {
      const textarea = this.textareaTarget
      textarea.style.height = "auto"
      textarea.style.height = Math.min(textarea.scrollHeight, 200) + "px"
    }
  }

  handleSuccess(event) {
    if (event.detail.success) {
      this.close()
    }
  }

  disconnect() {
    document.removeEventListener("keydown", this.closeOnEscape)
    document.body.style.overflow = ""
  }
}
