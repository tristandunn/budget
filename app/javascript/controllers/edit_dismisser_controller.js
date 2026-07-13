import { Controller } from "@hotwired/stimulus";

/*
 * Dismisses an inline edit within a turbo-frame on the Escape key by following
 * its cancel link, restoring the original view. Stops the event so it does not
 * bubble to document-level handlers, such as clearing the selection.
 */
export default class extends Controller {
  static targets = ["cancel"];

  cancel(event) {
    event.preventDefault();
    event.stopPropagation();

    this.cancelTarget.click();
  }
}
