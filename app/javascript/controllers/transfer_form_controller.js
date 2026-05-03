import { Controller } from "@hotwired/stimulus";

/*
 * Validates the transfer form before submission. Asks each account picker
 * to validate itself and checks the amount is a non-zero number; cancels
 * the submit when any required field is missing so the user can see which
 * fields need a value.
 */
export default class extends Controller {
  static outlets = ["from-account-picker", "to-account-picker"];

  static targets = ["amount"];

  validate(event) {
    const valid = [
      this.fromAccountPickerOutlet.validate(),
      this.toAccountPickerOutlet.validate(),
      this.#validateAmount()
    ].every(Boolean);

    if (!valid) {
      event.preventDefault();
    }
  }

  #validateAmount() {
    const value = parseFloat(this.amountTarget.value);
    const valid = !isNaN(value) && value !== 0;

    if (!valid) {
      this.amountTarget.classList.remove("text-black");
      this.amountTarget.classList.add("text-red-700");
    }

    return valid;
  }
}
