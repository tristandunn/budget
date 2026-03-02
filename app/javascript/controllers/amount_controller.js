import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    this.#updateColor();
  }

  input() {
    this.#updateColor();
  }

  keydown(event) {
    if (event.key === "-") {
      event.preventDefault();

      this.#toggleSign();
    } else if (this.#isZero() && (/^\d$/).test(event.key)) {
      event.preventDefault();

      this.element.value = `-${event.key}`;
      this.#updateColor();
    } else if (this.#isInvalidKey(event)) {
      event.preventDefault();
    }
  }

  #isInvalidKey(event) {
    if (event.ctrlKey || event.metaKey || event.key.length !== 1) {
      return false;
    } else {
      return !(/[\d.]/).test(event.key);
    }
  }

  #isZero() {
    return parseFloat(this.element.value) === 0;
  }

  #toggleSign() {
    const value = parseFloat(this.element.value) || 0;

    this.element.value = (-value).toFixed(2);
    this.#updateColor();
  }

  #updateColor() {
    const isNegative = parseFloat(this.element.value) < 0;

    this.element.classList.toggle("text-red-600", isNegative);
    this.element.classList.toggle("text-black", !isNegative);
  }
}
