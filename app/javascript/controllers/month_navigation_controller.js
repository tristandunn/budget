import { Controller } from "@hotwired/stimulus";

/*
 * Maps the left and right arrow keys to the previous and next month links,
 * enabling quick month navigation on the desktop budget view.
 */
export default class extends Controller {
  static targets = ["previous", "next"];

  connect() {
    this.#boundNavigate = this.#navigate.bind(this);

    document.addEventListener("keydown", this.#boundNavigate);
  }

  disconnect() {
    document.removeEventListener("keydown", this.#boundNavigate);
  }

  #boundNavigate = null;

  #navigable(event) {
    const target = event.target;

    return !(
      event.metaKey ||
      event.ctrlKey ||
      event.altKey ||
      target.isContentEditable ||
      ["INPUT", "SELECT", "TEXTAREA"].includes(target.tagName) ||
      document.querySelector("dialog[open]")
    );
  }

  #navigate(event) {
    if (event.key !== "ArrowLeft" && event.key !== "ArrowRight") {
      return;
    }

    if (this.#navigable(event)) {
      event.preventDefault();

      if (event.key === "ArrowLeft") {
        this.#visit(this.previousTarget);
      } else {
        this.#visit(this.nextTarget);
      }
    }
  }

  #visit(link) {
    if (link.getAttribute("aria-disabled") !== "true") {
      link.click();
    }
  }
}
