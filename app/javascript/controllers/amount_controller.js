import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = { "positive": Boolean };

  #handleFormdata;

  #positive = false;

  connect() {
    if (this.positiveValue) {
      this.#positive = true;
    } else {
      const initial = parseFloat(this.#unformat(this.element.value));

      if (!isNaN(initial) && initial > 0) {
        this.#positive = true;
      }
    }

    this.#render(this.element.value);

    if (this.element.form) {
      this.#handleFormdata = (event) => {
        event.formData.set(this.element.name, this.#unformat(this.element.value));
      };

      this.element.form.addEventListener("formdata", this.#handleFormdata);
    }
  }

  disconnect() {
    if (this.element.form && this.#handleFormdata) {
      this.element.form.removeEventListener("formdata", this.#handleFormdata);
    }
  }

  input() {
    const oldValue   = this.element.value,
          oldCursor  = this.element.selectionStart,
          digitCount = this.#countTypedCharacters(oldValue.slice(0, oldCursor));

    this.element.value = this.#format(oldValue);

    this.#restoreCursor(digitCount);
    this.#updateColor();
  }

  paste(event) {
    event.preventDefault();

    const pasted  = event.clipboardData.getData("text/plain"),
          cleaned = pasted.replace(/[^\d.]/g, "");

    let sign;

    if (this.positiveValue) {
      sign = "";
    } else if (pasted.includes("-")) {
      this.#positive = false;
      sign = "-";
    } else if (pasted.includes("+")) {
      this.#positive = true;
      sign = "";
    } else {
      sign = this.#positive
        ? ""
        : "-";
    }

    this.#render(`${sign}${cleaned}`);
  }

  keydown(event) {
    if (this.#shouldDelegateToBrowser(event)) {
      return;
    }

    event.preventDefault();

    if (this.positiveValue && (event.key === "-" || event.key === "+")) {
      return;
    }

    if (event.key === "-") {
      this.#positive = false;
      this.#toggleSign();
    } else if (event.key === "+") {
      this.#positive = true;
      this.#makePositive();
    } else if ((/^\d$/).test(event.key)) {
      const sign = this.#positive
        ? ""
        : "-";

      this.#render(`${sign}${event.key}`);
    }
  }

  #countTypedCharacters(text) {
    return (text.match(/[\d.]/g) || []).length;
  }

  #format(value) {
    const text       = String(value),
          isNegative = text.includes("-"),
          cleaned    = text.replace(/[^\d.]/g, "");

    if (cleaned === "" || cleaned === "." || cleaned === "0") {
      return "$0.00";
    }

    const parts        = cleaned.split("."),
          fractional   = parts.slice(1).join(""),
          integerPart  = Number(parts[0] || "0").toLocaleString("en-US"),
          decimalPart  = parts.length > 1
            ? `.${fractional.slice(0, 2)}`
            : "",
          sign         = isNegative && parseFloat(cleaned)
            ? "-"
            : "";

    return `${sign}$${integerPart}${decimalPart}`;
  }

  #isAllSelected() {
    return this.element.value.length > 0 &&
      this.element.selectionStart === 0 &&
      this.element.selectionEnd === this.element.value.length;
  }

  #isZero() {
    return !parseFloat(this.#unformat(this.element.value));
  }

  #makePositive() {
    const text     = this.#unformat(this.element.value),
          positive = text.startsWith("-")
            ? text.slice(1)
            : text;

    this.#render(positive);
  }

  #render(text) {
    this.element.value = this.#format(text);

    this.#updateColor();
  }

  #restoreCursor(targetCount) {
    const value = this.element.value;

    if (targetCount === 0) {
      const offset = value.indexOf("$") + 1;

      this.element.setSelectionRange(offset, offset);

      return;
    }

    let count = 0;

    for (let position = 0; position < value.length; position += 1) {
      if ((/[\d.]/).test(value[position])) {
        count += 1;

        if (count === targetCount) {
          this.element.setSelectionRange(position + 1, position + 1);

          return;
        }
      }
    }

    this.element.setSelectionRange(value.length, value.length);
  }

  #shouldDelegateToBrowser(event) {
    if (event.ctrlKey || event.metaKey || event.key.length !== 1) {
      return true;
    }

    if (event.key === "-" || event.key === "+") {
      return false;
    }

    if ((/^\d$/).test(event.key)) {
      if (this.#isZero() || this.#isAllSelected()) {
        return false;
      }

      return true;
    }

    return event.key === ".";
  }

  #toggleSign() {
    const text    = this.#unformat(this.element.value),
          toggled = text.startsWith("-")
            ? text.slice(1)
            : `-${text}`;

    this.#render(toggled);
  }

  #unformat(value) {
    return String(value).replace(/[$,]/g, "");
  }

  #updateColor() {
    const classList = this.element.classList;

    if (this.positiveValue) {
      classList.remove("text-red-700");
      classList.add("text-black");

      return;
    }

    const isNegative = parseFloat(this.#unformat(this.element.value)) < 0;

    classList.toggle("text-red-700", isNegative);
    classList.toggle("text-black", !isNegative);
  }
}
