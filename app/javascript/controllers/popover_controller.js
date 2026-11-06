import { Controller } from "@hotwired/stimulus";

/*
 * Toggles a popover menu, closing it on an outside click, the Escape key, or
 * before Turbo caches the page. Subclasses may override open, close, and
 * dismiss, where dismiss decides what an outside click does.
 */
export default class extends Controller {
  static targets = ["menu"];

  connect() {
    this.#boundClose = this.close.bind(this);
    this.#boundDismiss = this.dismiss.bind(this);
    this.#boundEscape = this.#closeOnEscape.bind(this);

    document.addEventListener("turbo:before-cache", this.#boundClose);
  }

  disconnect() {
    document.removeEventListener("click", this.#boundDismiss);
    document.removeEventListener("keydown", this.#boundEscape);
    document.removeEventListener("turbo:before-cache", this.#boundClose);
  }

  // Hide the menu and stop listening for outside clicks and Escape.
  close() {
    this.menuTarget.classList.add("hidden");

    document.removeEventListener("click", this.#boundDismiss);
    document.removeEventListener("keydown", this.#boundEscape);
  }

  // Return whether the menu is hidden.
  get closed() {
    return this.menuTarget.classList.contains("hidden");
  }

  // Handle an outside click by closing the menu.
  dismiss() {
    this.close();
  }

  // Stop a click from reaching the outside click listener.
  keep(event) {
    event.stopPropagation();
  }

  // Show the menu and listen for outside clicks and Escape.
  open() {
    this.menuTarget.classList.remove("hidden");

    document.addEventListener("click", this.#boundDismiss);
    document.addEventListener("keydown", this.#boundEscape);
  }

  // Open the menu when closed and close it when open.
  toggle(event) {
    event.stopPropagation();

    if (this.closed) {
      this.open();
    } else {
      this.close();
    }
  }

  #boundClose = null;

  #boundDismiss = null;

  #boundEscape = null;

  #closeOnEscape(event) {
    if (event.key === "Escape") {
      this.close();
    }
  }
}
