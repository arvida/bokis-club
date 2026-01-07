import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

export default class extends Controller {
  static targets = ["list", "template", "generateBtn"]
  static values = {
    generateUrl: String
  }

  connect() {
    this.initSortable()
  }

  disconnect() {
    if (this.sortable) {
      this.sortable.destroy()
    }
  }

  initSortable() {
    this.sortable = new Sortable(this.listTarget, {
      handle: ".drag-handle",
      animation: 150,
      ghostClass: "opacity-50"
    })
  }

  add(event) {
    event.preventDefault()
    this.addQuestion("")
  }

  addQuestion(text) {
    const template = this.templateTarget.innerHTML
    const id = Date.now()
    const html = template.replace(/NEW_ID/g, id)

    this.listTarget.insertAdjacentHTML("beforeend", html)

    if (text) {
      const lastInput = this.listTarget.querySelector(`[data-question-id="${id}"] textarea`)
      if (lastInput) {
        lastInput.value = text
      }
    }
  }

  remove(event) {
    event.preventDefault()
    const item = event.target.closest("[data-question-id]")
    if (item) {
      item.remove()
    }
  }

  async generate(event) {
    event.preventDefault()

    if (!this.hasGenerateUrlValue) return

    // Get the selected club_book_id from the form
    const clubBookSelect = document.querySelector("[name='meeting[club_book_id]']")
    const clubBookId = clubBookSelect?.value

    if (!clubBookId) {
      // No book selected, can't generate questions
      return
    }

    const btn = this.generateBtnTarget
    const originalText = btn.innerHTML
    btn.disabled = true
    btn.innerHTML = `
      <svg class="animate-spin w-4 h-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
        <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
      </svg>
      <span>Genererar...</span>
    `

    // Collect existing questions to avoid duplicates
    const existingQuestions = Array.from(this.listTarget.querySelectorAll("textarea"))
      .map(ta => ta.value.trim())
      .filter(q => q.length > 0)

    try {
      const response = await fetch(this.generateUrlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector("[name='csrf-token']").content
        },
        body: JSON.stringify({ club_book_id: clubBookId, existing_questions: existingQuestions })
      })

      if (response.ok) {
        const data = await response.json()
        data.questions.forEach(q => this.addQuestion(q))
      }
    } catch (error) {
      console.error("Failed to generate questions:", error)
    } finally {
      btn.disabled = false
      btn.innerHTML = originalText
    }
  }
}
