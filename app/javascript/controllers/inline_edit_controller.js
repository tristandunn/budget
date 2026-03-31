import { Controller } from "@hotwired/stimulus";

const CLEANUP_DELAY_MS = 1000;

export default class extends Controller {
  static targets = ["input"];

  cancel() {
    const input = this.inputTarget;

    input.value = this.originalValue;
    input.blur();
  }

  inputTargetConnected() {
    const input = this.inputTarget;

    input.focus();
    input.select();

    this.originalValue = input.value;
  }

  prefocus() {
    const input = document.createElement("input");

    input.style.left     = "-9999px";
    input.style.opacity  = "0";
    input.style.position = "fixed";

    document.body.appendChild(input);

    input.focus();

    window.setTimeout(() => {
      input.remove();
    }, CLEANUP_DELAY_MS);
  }

  submit() {
    const input = this.inputTarget;

    if (
      input.value !== this.originalValue &&
      input.value.trim() !== ""
    ) {
      input.form.requestSubmit();
    } else {
      input.closest("turbo-frame").src = window.location.href;
    }
  }

  submitOnEnter(event) {
    event.preventDefault();

    this.inputTarget.blur();
  }
}
