import { Controller } from "@hotwired/stimulus";
import DialogCloser from "shared/dialog_closer";

/*
 * Opens and closes a modal dialog with slide transitions, dismissing it once
 * the slide-out transition ends or the fallback delay elapses.
 */
export default class extends Controller {
  static targets = ["dialog"];

  #closer = new DialogCloser();

  // Open the dialog when a frame finishes loading.
  open() {
    const dialog = this.dialogTarget,
          frame = dialog.querySelector("turbo-frame");

    /*
     * When a form submission redirects, the frame loads with no content.
     * Dismiss the dialog and visit the redirected page.
     */
    if (frame && !frame.innerHTML.trim()) {
      this.#dismiss(dialog, frame.src);

      return;
    }

    this.#closer.cancel(() => {
      dialog.classList.remove("closing");
    });

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
    if (!this.#reducedMotion()) {
      void dialog.offsetHeight;
    }

    dialog.classList.add("open");
  }

  // Animate the dialog closed, then close it after the transition.
  close() {
    const dialog = this.dialogTarget;

    this.#closeWithMotion(dialog, () => {
      this.#reset(dialog);
    });
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

  /*
   * Run the close callback immediately when the user prefers reduced motion,
   * otherwise hand off to the closer, which forces a reflow and then adds the
   * closing class to slide the dialog out before running the callback once the
   * transition ends.
   */
  #closeWithMotion(dialog, onClosed) {
    if (this.#reducedMotion()) {
      this.#closer.cancel();
      onClosed();

      return;
    }

    this.#closer.close(
      dialog,
      () => {
        dialog.classList.add("closing");
      },
      onClosed
    );
  }

  /*
   * Slide the dialog closed, then visit the given URL. Cancel any in-flight
   * close first so #closeWithMotion is not dropped by the guard against
   * overlapping closes, otherwise a dismiss that lands while the dialog is
   * already animating shut would skip the redirect.
   */
  #dismiss(dialog, url) {
    this.#closer.cancel();

    this.#closeWithMotion(dialog, () => {
      this.#reset(dialog);

      /*
       * Visit with the replace action so Turbo treats the same-URL navigation
       * as a page refresh and morphs the DOM, preserving scroll position
       * instead of performing a full reload.
       */
      Turbo.visit(url, { "action": "replace" });
    });
  }

  // Return whether the user prefers reduced motion.
  #reducedMotion() {
    return window.matchMedia("(prefers-reduced-motion: reduce)").matches;
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
