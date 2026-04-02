import { Controller } from "@hotwired/stimulus";

// Toggles an icon between muted and active colors based on field value.
export default class extends Controller {
  static targets = ["icon"];

  connect() {
    this.update();
  }

  // Focus or open the field when the row is clicked.
  focus(event) {
    const field = this.element.querySelector("input, select");

    if (!field || field.contains(event.target)) {
      return;
    }

    if (field.showPicker) {
      field.showPicker();
    } else {
      field.focus();
    }
  }

  // Update icon color when the field value changes.
  update() {
    const filled = this.element.querySelector("input, select").value.trim() !== "";

    this.iconTarget.classList.toggle("text-taupe-400", !filled);
    this.iconTarget.classList.toggle("text-indigo-600", filled);
  }
}
