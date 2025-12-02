import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["radio", "field", "label", "input"]

  toggle() {
    const selectedRadio = this.radioTargets.find(radio => radio.checked)
    const locationType = selectedRadio?.value

    if (locationType === "tbd") {
      this.fieldTarget.classList.add("hidden")
    } else {
      this.fieldTarget.classList.remove("hidden")

      if (this.hasLabelTarget) {
        const labelText = locationType === "video" ? "Länk" : "Adress"
        this.labelTarget.textContent = labelText
      }

      if (this.hasInputTarget) {
        const placeholder = locationType === "video"
          ? "https://zoom.us/j/..."
          : "Skriv adressen..."
        this.inputTarget.placeholder = placeholder
      }
    }
  }
}
