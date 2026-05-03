import { Controller } from "@hotwired/stimulus";

// Opens and closes a dialog with slide transitions.
export default class extends Controller {
  static targets = ["dialog"];

  // Open the dialog when a frame finishes loading.
  open() {
    const dialog = this.dialogTarget;
    const frame = dialog.querySelector("turbo-frame");

    /*
     * When a form submission redirects, the frame loads with no content.
     * Dismiss the dialog and visit the redirected page.
     */
    if (frame && !frame.innerHTML.trim()) {
      this.#dismiss(dialog, frame.src);

      return;
    }

    /*
     * Skip showModal when the dialog is already open. This happens when
     * a turbo frame inside the open dialog loads new content, such as
     * navigating from the details view to the rename form.
     */
    if (!dialog.open) {
      dialog.showModal();
    }

    /*
     * Force a reflow so the browser registers the off-screen position
     * before adding the open class to trigger the slide-in transition.
     * Skip when the user prefers reduced motion since no transition runs.
     */
    if (!window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
      this.#forceReflow(dialog);
    }

    dialog.classList.add("open");
  }

  // Animate the dialog closed, then close it after the transition.
  close() {
    const dialog = this.dialogTarget;

    if (dialog.classList.contains("closing")) {
      return;
    }

    const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

    if (reducedMotion) {
      this.#reset(dialog);

      return;
    }

    dialog.addEventListener(
      "transitionend",
      () => {
        return this.#reset(dialog);
      },
      { "once": true }
    );

    /*
     * Force a reflow so the browser registers the on-screen position before
     * adding the closing class. Without this, a pending layout change (such as
     * a turbo stream replacing the frame contents) can be batched with the
     * class change and skip the slide-out transition entirely.
     */
    this.#forceReflow(dialog);
    dialog.classList.add("closing");
  }

  // Close when clicking the backdrop area of the dialog.
  backdropClose(event) {
    if (event.target === this.dialogTarget) {
      this.close();
    }
  }

  // Prevent the Escape key from closing the dialog without animation.
  cancel(event) {
    event.preventDefault();

    this.close();
  }

  // Slide the dialog closed, then visit the given URL.
  #dismiss(dialog, url) {
    const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

    if (reducedMotion) {
      this.#reset(dialog);
      Turbo.visit(url);

      return;
    }

    dialog.addEventListener(
      "transitionend",
      () => {
        this.#reset(dialog);
        Turbo.visit(url);
      },
      { "once": true }
    );

    this.#forceReflow(dialog);
    dialog.classList.add("closing");
  }

  /*
   * Read offsetHeight to force a synchronous layout flush, ensuring any
   * pending style or DOM changes are applied before the next class change.
   */
  #forceReflow(dialog) {
    return dialog.offsetHeight;
  }

  // Reset the dialog state and clear the frame content.
  #reset(dialog) {
    dialog.classList.remove("closing", "open");
    dialog.close();

    const frame = dialog.querySelector("turbo-frame");

    if (frame) {
      frame.innerHTML = "";
    }
  }
}
