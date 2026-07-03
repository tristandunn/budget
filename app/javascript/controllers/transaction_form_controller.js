import { Controller } from "@hotwired/stimulus";

/*
 * Validates the transaction form before submission. Asks each required picker
 * to validate itself and checks the amount is a non-zero number, cancelling
 * the submit when any required field is missing so the user can see which
 * fields need a value.
 */
export default class extends Controller {
  static outlets = ["account-picker", "category-picker", "payee-picker"];

  static targets = ["amount"];

  validate(event) {
    const valid = [
      this.payeePickerOutlet.validate(),
      this.categoryPickerOutlet.validate(),
      this.accountPickerOutlet.validate(),
      this.#validateAmount()
    ].every(Boolean);

    if (!valid) {
      event.preventDefault();
    }
  }

  #validateAmount() {
    const value = parseFloat(this.amountTarget.value.replace(/[$,]/g, ""));
    const valid = !isNaN(value) && value !== 0;

    if (!valid) {
      const classList = this.amountTarget.classList;

      classList.remove("text-black");
      classList.add("text-red-700");
    }

    return valid;
  }
}
