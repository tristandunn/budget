import { Controller } from "@hotwired/stimulus";

/*
 * Limits a text input to a single arithmetic operation on decimal numbers,
 * using the plus and minus operators. Handles operator keypresses and pastes,
 * collapsing consecutive operators so only the last one in a run is kept and
 * limiting the value to the first operation. A leading minus sign is a sign
 * rather than an operation, so it never counts against that limit.
 */
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

    const cursor = this.#limitToOperation(element.value.slice(0, element.selectionStart)).length;

    element.value = this.#limitToOperation(element.value);
    element.setSelectionRange(cursor, cursor);
  }

  #collapseOperators(value) {
    return value.replace(/[+-]+/g, (match) => {
      return match.slice(-1);
    });
  }

  #handleOperator(operator) {
    const element = this.element,
          value = this.#valueWithOperator(element.value, operator);

    if (value !== element.value) {
      element.value = value;
      element.setSelectionRange(-1, -1);
    }
  }

  #hasOperator(value) {
    return (/[+-]/).test(value.slice(1));
  }

  #isInvalidKey(event) {
    if (event.ctrlKey || event.metaKey || event.key.length !== 1) {
      return false;
    } else {
      return !(/[\d.+-]/).test(event.key);
    }
  }

  #isZeroOrEmpty(value) {
    return value === "" || !this.#hasOperator(value) && parseFloat(value) === 0;
  }

  #limitToOperation(value) {
    return (/^[+-]?[\d.]*(?:[+-][\d.]*)?/).exec(this.#collapseOperators(value))[0];
  }

  #replaceTrailingOperator(value) {
    return value.replace(/[+-]$/, "");
  }

  #valueWithOperator(value, operator) {
    if (this.#isZeroOrEmpty(value)) {
      if (operator === "-") {
        return "-";
      } else {
        return value;
      }
    } else {
      const stripped = this.#replaceTrailingOperator(value);

      if (this.#hasOperator(stripped)) {
        return value;
      } else {
        return stripped + operator;
      }
    }
  }
}
