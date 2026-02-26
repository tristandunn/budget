import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input"];

  connect() {
    this.originalValue = this.inputTarget.value;
    this.inputTarget.select();
  }

  cancel() {
    this.inputTarget.value = this.originalValue;
    this.inputTarget.blur();
  }

  submit() {
    if (
      this.inputTarget.value !== this.originalValue &&
      this.inputTarget.value.trim() !== ""
    ) {
      this.element.requestSubmit();
    } else {
      this.element.closest("turbo-frame").src = window.location.href;
    }
  }

  submitOnEnter(event) {
    event.preventDefault();

    this.inputTarget.blur();
  }
}
