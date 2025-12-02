import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "loading", "results", "selected", "selectedCover", "selectedTitle", "selectedAuthors", "hiddenId", "manualEntry", "manualInput"]
  static values = { url: String, clubId: String }

  connect() {
    this.timeout = null
  }

  search() {
    clearTimeout(this.timeout)
    const query = this.inputTarget.value.trim()

    if (query.length < 2) {
      return
    }

    this.showLoading()

    this.timeout = setTimeout(() => {
      this.performSearch(query)
    }, 300)
  }

  async performSearch(query) {
    try {
      const response = await fetch(`${this.urlValue}?q=${encodeURIComponent(query)}`, {
        headers: {
          "Accept": "text/vnd.turbo-stream.html, text/html",
          "Turbo-Frame": "book-search-results"
        }
      })

      if (response.ok) {
        const html = await response.text()
        this.resultsTarget.innerHTML = html
      }
    } catch (error) {
      console.error("Search failed:", error)
    } finally {
      this.hideLoading()
    }
  }

  selectBook(event) {
    const button = event.currentTarget
    const id = button.dataset.bookId
    const title = button.dataset.bookTitle
    const authors = button.dataset.bookAuthors
    const cover = button.dataset.bookCover

    this.hiddenIdTarget.value = id
    this.selectedTitleTarget.textContent = title
    this.selectedAuthorsTarget.textContent = authors

    if (cover) {
      const img = document.createElement("img")
      img.src = cover
      img.alt = title
      img.className = "w-full rounded shadow-sm"
      this.selectedCoverTarget.replaceChildren(img)
    } else {
      const placeholder = document.createElement("div")
      placeholder.className = "w-full aspect-[2/3] bg-vermillion rounded shadow-sm flex items-center justify-center p-2"
      const span = document.createElement("span")
      span.className = "text-white text-xs font-display text-center leading-tight"
      span.textContent = title.substring(0, 30)
      placeholder.appendChild(span)
      this.selectedCoverTarget.replaceChildren(placeholder)
    }

    this.resultsTarget.classList.add("hidden")
    this.selectedTarget.classList.remove("hidden")
    this.inputTarget.classList.add("hidden")
    if (this.hasManualEntryTarget) {
      this.manualEntryTarget.classList.add("hidden")
    }
  }

  clearSelection() {
    this.hiddenIdTarget.value = ""
    this.selectedTarget.classList.add("hidden")
    this.resultsTarget.classList.remove("hidden")
    this.inputTarget.classList.remove("hidden")
    this.inputTarget.value = ""
    this.inputTarget.focus()
  }

  showManualEntry() {
    this.resultsTarget.classList.add("hidden")
    this.inputTarget.classList.add("hidden")
    if (this.hasManualEntryTarget) {
      this.manualEntryTarget.classList.remove("hidden")
      this.manualInputTargets.forEach(input => input.disabled = false)
    }
  }

  hideManualEntry() {
    if (this.hasManualEntryTarget) {
      this.manualEntryTarget.classList.add("hidden")
      this.manualInputTargets.forEach(input => input.disabled = true)
    }
    this.resultsTarget.classList.remove("hidden")
    this.inputTarget.classList.remove("hidden")
    this.inputTarget.focus()
  }

  showLoading() {
    if (this.hasLoadingTarget) {
      this.loadingTarget.classList.remove("hidden")
    }
  }

  hideLoading() {
    if (this.hasLoadingTarget) {
      this.loadingTarget.classList.add("hidden")
    }
  }
}
