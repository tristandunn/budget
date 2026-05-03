import { Controller } from "@hotwired/stimulus";

/*
 * Dispatches a bubbling dialog:close event when this controller's element
 * connects, dismissing the enclosing dialog with its slide-down animation.
 */
export default class extends Controller {
  connect() {
    this.element.dispatchEvent(new window.CustomEvent("dialog:close", { "bubbles": true }));
  }
}
