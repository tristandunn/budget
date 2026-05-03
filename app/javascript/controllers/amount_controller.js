import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  #positive = false;

  connect() {
    if (this.#positiveOnly()) {
      this.#positive = true;
    }

    this.#updateColor();
  }

  input() {
    this.#updateColor();
  }

  paste(event) {
    event.preventDefault();

    const pasted = event.clipboardData.getData("text/plain"),
          cleaned = pasted.replace(/[^\d.]/g, ""),
          value = parseFloat(cleaned) || 0;

    if (this.#positive) {
      this.element.value = value.toFixed(2);
    } else {
      this.element.value = (-Math.abs(value)).toFixed(2);
    }

    this.#updateColor();
  }

  keydown(event) {
    if (this.#positiveOnly() && (event.key === "-" || event.key === "+")) {
      event.preventDefault();

      return;
    }

    if (event.key === "-") {
      event.preventDefault();

      this.#positive = false;
      this.#toggleSign();
    } else if (event.key === "+") {
      event.preventDefault();

      this.#positive = true;
      this.#makePositive();
    } else if (this.#isZero() && !this.#positive && (/^\d$/).test(event.key)) {
      event.preventDefault();

      this.element.value = `-${event.key}`;
      this.#updateColor();
    } else if (this.#isZero() && this.#positive && (/^\d$/).test(event.key)) {
      event.preventDefault();

      this.element.value = event.key;
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

  #makePositive() {
    const value = Math.abs(parseFloat(this.element.value) || 0);

    this.element.value = value.toFixed(2);
    this.#updateColor();
  }

  #isZero() {
    return !parseFloat(this.element.value);
  }

  #positiveOnly() {
    return this.element.dataset.amountPositiveValue === "true";
  }

  #toggleSign() {
    const value = parseFloat(this.element.value) || 0;

    this.element.value = (-value).toFixed(2);
    this.#updateColor();
  }

  #updateColor() {
    if (this.#positiveOnly()) {
      this.element.classList.remove("text-red-700");
      this.element.classList.add("text-black");

      return;
    }

    const isNegative = parseFloat(this.element.value) < 0;

    this.element.classList.toggle("text-red-700", isNegative);
    this.element.classList.toggle("text-black", !isNegative);
  }
}
