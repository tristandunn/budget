import { Controller } from "@hotwired/stimulus";

const CLEANUP_DELAY_MS = 1000;

/*
 * Manages an inline edit input, focusing and selecting it when it connects.
 * Submits the form when the value changes to a non-empty string; otherwise
 * reloads the enclosing turbo-frame to discard the edit. The escape key
 * restores the original value before blurring, discarding the edit.
 */
export default class extends Controller {
  static targets = ["input"];

  inputTargetConnected() {
    const input = this.inputTarget;

    input.focus();
    input.select();

    this.originalValue = input.value;
  }

  cancel(event) {
    event.preventDefault();
    event.stopPropagation();

    const input = this.inputTarget;

    input.value = this.originalValue;
    input.blur();
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
