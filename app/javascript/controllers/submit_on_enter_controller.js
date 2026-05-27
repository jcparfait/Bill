import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="submit-on-enter"
export default class extends Controller {
  submit(event) {
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault()
      this.element.requestSubmit()
    }
  }
}
