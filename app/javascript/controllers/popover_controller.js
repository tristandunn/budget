import { Controller } from "@hotwired/stimulus";

/*
 * Toggles a popover menu, closing it on an outside click or before Turbo
 * caches the page.
 */
export default class extends Controller {
  static targets = ["menu"];

  connect() {
    this.#boundClose = this.#close.bind(this);

    document.addEventListener("turbo:before-cache", this.#boundClose);
  }

  disconnect() {
    document.removeEventListener("click", this.#boundClose);
    document.removeEventListener("turbo:before-cache", this.#boundClose);
  }

  toggle(event) {
    event.stopPropagation();

    if (this.menuTarget.classList.contains("hidden")) {
      this.#open();
    } else {
      this.#close();
    }
  }

  #boundClose = null;

  #close() {
    this.menuTarget.classList.add("hidden");
    document.removeEventListener("click", this.#boundClose);
  }

  #open() {
    this.menuTarget.classList.remove("hidden");
    document.addEventListener("click", this.#boundClose);
  }
}
