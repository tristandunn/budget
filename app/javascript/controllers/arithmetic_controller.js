import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  keydown(event) {
    if (event.key === "+") {
      event.preventDefault();

      this.#handleOperator("+");
    } else if (event.key === "-") {
      event.preventDefault();

      this.#handleMinus();
    } else if (this.#isInvalidKey(event)) {
      event.preventDefault();
    }
  }

  #handleMinus() {
    const value = this.element.value;

    if (this.#isZeroOrEmpty(value)) {
      this.element.value = "-";
    } else {
      this.element.value = this.#replaceTrailingOperator(value) + "-";
    }

    this.#moveCursorToEnd();
  }

  #handleOperator(operator) {
    const value = this.element.value;

    if (this.#isZeroOrEmpty(value)) {
      return;
    }

    this.element.value = this.#replaceTrailingOperator(value) + operator;
    this.#moveCursorToEnd();
  }

  #isInvalidKey(event) {
    if (event.ctrlKey || event.metaKey || event.key.length !== 1) {
      return false;
    } else {
      return !(/[\d.+-]/).test(event.key);
    }
  }

  #isZeroOrEmpty(value) {
    return value === "" ||
      !(/[+-]/).test(value.slice(1)) && parseFloat(value) === 0;
  }

  #moveCursorToEnd() {
    const length = this.element.value.length;

    this.element.setSelectionRange(length, length);
  }

  #replaceTrailingOperator(value) {
    return value.replace(/[+-]$/, "");
  }
}
