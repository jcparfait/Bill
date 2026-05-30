import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { chatId: Number }

  accept(event) {
    event.preventDefault()
    this.element.classList.remove("cocktail-card-slide-in")
    this.element.classList.add("cocktail-card-slide-out-left")
    this.element.addEventListener("animationend", () => {
      this.element.closest(".cocktail-card-container").innerHTML = ""
    }, { once: true })
  }

  collapse(event) {
    event.preventDefault()
    this.element.classList.remove("cocktail-card-slide-in")
    this.element.classList.add("cocktail-card-slide-out-right")
    this.element.addEventListener("animationend", () => {
      this.element.closest(".cocktail-card-container").innerHTML = ""
    }, { once: true })
  }
}
