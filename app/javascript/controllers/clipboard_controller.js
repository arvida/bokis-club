import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source", "button"]

  async copy() {
    const text = this.sourceTarget.value

    try {
      await navigator.clipboard.writeText(text)
      this.showSuccess()
    } catch {
      this.fallbackCopy(text)
    }
  }

  fallbackCopy(text) {
    this.sourceTarget.select()
    document.execCommand("copy")
    this.showSuccess()
  }

  showSuccess() {
    const originalText = this.buttonTarget.textContent
    this.buttonTarget.textContent = "Kopierad!"
    this.buttonTarget.classList.add("bg-sage", "text-paper")
    this.buttonTarget.classList.remove("bg-ink")

    setTimeout(() => {
      this.buttonTarget.textContent = originalText
      this.buttonTarget.classList.remove("bg-sage", "text-paper")
      this.buttonTarget.classList.add("bg-ink")
    }, 2000)
  }
}
