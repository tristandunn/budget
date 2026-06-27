import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  keydown(event) {
    if (event.key === "+" || event.key === "-") {
      event.preventDefault();

      this.#handleOperator(event.key);
    } else if (this.#isInvalidKey(event)) {
      event.preventDefault();
    }
  }

  paste(event) {
    event.preventDefault();

    const element = this.element,
          cleaned = event.clipboardData.getData("text/plain").replace(/[^\d.+-]/g, "");

    element.setRangeText(cleaned, element.selectionStart, element.selectionEnd, "end");

    const cursor = this.#collapseOperators(element.value.slice(0, element.selectionStart)).length;

    element.value = this.#collapseOperators(element.value);
    element.setSelectionRange(cursor, cursor);
  }

  #collapseOperators(value) {
    return value.replace(/[+-]+/g, (match) => {
      return match.slice(-1);
    });
  }

  #handleOperator(operator) {
    const element = this.element,
          value = element.value;

    if (this.#isZeroOrEmpty(value)) {
      if (operator === "-") {
        element.value = "-";
      }
    } else {
      element.value = this.#replaceTrailingOperator(value) + operator;
    }

    element.setSelectionRange(-1, -1);
  }

  #isInvalidKey(event) {
    if (event.ctrlKey || event.metaKey || event.key.length !== 1) {
      return false;
    } else {
      return !(/[\d.+-]/).test(event.key);
    }
  }

  #isZeroOrEmpty(value) {
    return value === "" || !(/[+-]/).test(value.slice(1)) && parseFloat(value) === 0;
  }

  #replaceTrailingOperator(value) {
    return value.replace(/[+-]$/, "");
  }
}
