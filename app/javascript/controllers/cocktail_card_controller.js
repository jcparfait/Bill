import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { chatId: Number }

  accept(event) {
    event.preventDefault()
    this.persistChoice(`/chats/${this.chatIdValue}/save_cocktail`)
    this.dismiss("cocktail-card-slide-out-left")
  }

  decline(event) {
    event.preventDefault()

    if (!event.currentTarget.dataset.saved) {
      this.persistChoice(`/chats/${this.chatIdValue}/remove_cocktail`)
    }

    this.dismiss("cocktail-card-slide-out-right")
  }

  close(event) {
    event.preventDefault()
    this.dismiss("cocktail-card-slide-out-right")
  }

  persistChoice(url) {
    fetch(url, {
      method: "PATCH",
      headers: {
        "X-CSRF-Token": this.csrfToken(),
        "Accept": "text/plain"
      }
    }).catch(() => {})
  }

  dismiss(animationClass) {
    this.element.classList.remove("cocktail-card-slide-in")
    this.element.classList.add(animationClass)
    this.element.addEventListener("animationend", () => {
      this.element.closest(".cocktail-card-container").innerHTML = ""
    }, { once: true })
  }

  csrfToken() {
    return document.querySelector("meta[name='csrf-token']")?.content || ""
  }
}
