import { Controller } from "@hotwired/stimulus";

/*
 * Reveals an inline confirmation panel and cancels on the Escape key, an
 * outside click, or the cancel action.
 */
export default class extends Controller {
  static targets = ["panel"];

  connect() {
    this.#boundCancelOnEscape = this.#cancelOnEscape.bind(this);
    this.#boundCancelOnOutsideClick = this.#cancelOnOutsideClick.bind(this);

    this.cancel();
  }

  disconnect() {
    this.#stopListening();
  }

  prompt() {
    this.panelTarget.hidden = false;

    this.#startListening();
  }

  cancel() {
    this.panelTarget.hidden = true;

    this.#stopListening();
  }

  stop(event) {
    event.stopPropagation();
  }

  #boundCancelOnEscape = null;

  #boundCancelOnOutsideClick = null;

  #cancelOnEscape(event) {
    if (event.key === "Escape") {
      this.cancel();
    }
  }

  #cancelOnOutsideClick(event) {
    if (!this.element.contains(event.target)) {
      this.cancel();
    }
  }

  #startListening() {
    document.addEventListener("click", this.#boundCancelOnOutsideClick);
    document.addEventListener("keydown", this.#boundCancelOnEscape);
  }

  #stopListening() {
    document.removeEventListener("click", this.#boundCancelOnOutsideClick);
    document.removeEventListener("keydown", this.#boundCancelOnEscape);
  }
}
