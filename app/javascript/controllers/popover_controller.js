import { Controller } from "@hotwired/stimulus";

/*
 * Toggles a popover menu, closing it on an outside click, the Escape key, or
 * before Turbo caches the page.
 */
export default class extends Controller {
  static targets = ["menu"];

  connect() {
    this.#boundClose = this.#close.bind(this);
    this.#boundEscape = this.#closeOnEscape.bind(this);

    document.addEventListener("turbo:before-cache", this.#boundClose);
  }

  disconnect() {
    document.removeEventListener("click", this.#boundClose);
    document.removeEventListener("keydown", this.#boundEscape);
    document.removeEventListener("turbo:before-cache", this.#boundClose);
  }

  keep(event) {
    event.stopPropagation();
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

  #boundEscape = null;

  #close() {
    this.menuTarget.classList.add("hidden");
    document.removeEventListener("click", this.#boundClose);
    document.removeEventListener("keydown", this.#boundEscape);
  }

  #closeOnEscape(event) {
    if (event.key === "Escape") {
      this.#close();
    }
  }

  #open() {
    this.menuTarget.classList.remove("hidden");
    document.addEventListener("click", this.#boundClose);
    document.addEventListener("keydown", this.#boundEscape);
  }
}
