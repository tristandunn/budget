import { Controller } from "@hotwired/stimulus";

/*
 * Limits a text input to a single arithmetic operation on decimal numbers,
 * using the plus, minus, multiply, and divide operators.
 */
export default class extends Controller {
  keydown(event) {
    if (event.ctrlKey || event.metaKey) {
      return;
    }

    if ((/^[-+*/]$/).test(event.key)) {
      event.preventDefault();

      this.#handleOperator(event.key);
    } else if (this.#isInvalidKey(event)) {
      event.preventDefault();
    }
  }

  paste(event) {
    event.preventDefault();

    const element = this.element,
          pasted  = event.clipboardData.getData("text/plain").replace(/[^\d.+*/-]/g, ""),
          cleaned = this.#limitPastedDecimal(pasted);

    element.setRangeText(cleaned, element.selectionStart, element.selectionEnd, "end");

    const cursor = this.#limitToOperation(element.value.slice(0, element.selectionStart)).length;

    element.value = this.#limitToOperation(element.value);
    element.setSelectionRange(cursor, cursor);
  }

  #collapseOperators(value) {
    return value.replace(/[-+*/]+/g, (match) => {
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

  #hasDecimalInOperand() {
    const element = this.element,
          value   = element.value.replace(/^[-+]/, " "),
          before  = value.slice(0, element.selectionStart),
          after   = value.slice(element.selectionEnd);

    return (/\.[^-+*/]*$/).test(before) || (/^[^-+*/]*\./).test(after);
  }

  #hasOperator(value) {
    return (/[-+*/]/).test(value.slice(1));
  }

  #isInvalidKey(event) {
    if (event.key.length !== 1) {
      return false;
    } else if (event.key === ".") {
      return this.#hasDecimalInOperand();
    } else {
      return !(/\d/).test(event.key);
    }
  }

  #isZeroOrIncomplete(value) {
    const number = parseFloat(value);

    return Number.isNaN(number) || !this.#hasOperator(value) && number === 0;
  }

  #limitPastedDecimal(value) {
    if (this.#hasDecimalInOperand()) {
      return value.replace(/^[^-+*/]*/, (operand) => {
        return operand.replace(/\..*/, "");
      });
    } else {
      return value;
    }
  }

  #limitToOperation(value) {
    return (/^[-+]?\d*\.?\d*(?:[-+*/]\d*\.?\d*)?/).exec(this.#collapseOperators(value))[0];
  }

  #replaceTrailingOperator(value) {
    return value.replace(/[-+*/]$/, "");
  }

  #valueWithOperator(value, operator) {
    if (this.#isZeroOrIncomplete(value)) {
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
