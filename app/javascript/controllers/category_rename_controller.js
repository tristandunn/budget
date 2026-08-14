import { Controller } from "@hotwired/stimulus";

/*
 * Loads the rename form into a turbo-frame anchored to a selected subcategory's
 * name. The popover reveals itself via CSS once the frame finishes loading
 * (turbo-frame[complete]), so it never flashes an empty box. Opens only when the
 * row's selection checkbox is checked; otherwise the click falls through to the
 * default selection behavior. Dismisses on the Escape key, an outside click, or
 * before Turbo caches the page.
 */
export default class extends Controller {
  static targets = ["checkbox", "frame"];

  static values = { "url": String };

  connect() {
    this.#boundClose = this.#close.bind(this);
    this.#boundCloseOnEscape = this.#closeOnEscape.bind(this);
    this.#boundCloseOnOutsideClick = this.#closeOnOutsideClick.bind(this);

    document.addEventListener("turbo:before-cache", this.#boundClose);
  }

  disconnect() {
    document.removeEventListener("turbo:before-cache", this.#boundClose);

    this.#stopListening();
  }

  open(event) {
    if (this.hasCheckboxTarget && !this.checkboxTarget.checked) {
      return;
    }

    event?.preventDefault();
    event?.stopPropagation();

    // A frame with a src is already open (or loading); leave any typed input be.
    if (this.frameTarget.hasAttribute("src")) {
      return;
    }

    this.frameTarget.setAttribute("src", this.urlValue);

    this.#startListening();
  }

  close() {
    this.#close();
  }

  /*
   * Turbo runs autofocus while the popover is still hidden, so focus the field
   * ourselves once the frame loads and CSS reveals it.
   */
  focus() {
    this.frameTarget.querySelector("[autofocus]")?.focus();
  }

  #boundClose = null;

  #boundCloseOnEscape = null;

  #boundCloseOnOutsideClick = null;

  #close() {
    this.frameTarget.removeAttribute("src");
    this.frameTarget.removeAttribute("complete");
    this.frameTarget.innerHTML = "";

    this.#stopListening();
  }

  #closeOnEscape(event) {
    if (event.key === "Escape") {
      this.#close();
    }
  }

  #closeOnOutsideClick(event) {
    if (!this.element.contains(event.target)) {
      this.#close();
    }
  }

  #startListening() {
    document.addEventListener("click", this.#boundCloseOnOutsideClick);
    document.addEventListener("keydown", this.#boundCloseOnEscape);
  }

  #stopListening() {
    document.removeEventListener("click", this.#boundCloseOnOutsideClick);
    document.removeEventListener("keydown", this.#boundCloseOnEscape);
  }
}
