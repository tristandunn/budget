import { Controller } from "@hotwired/stimulus";

/*
 * Fallback delay, in milliseconds, after which a closing dialog is forced
 * shut even if no transition event arrives. It is longer than the 300ms
 * slide-out transition so it only fires when the expected transitionend is
 * missing, such as when Firefox cancels the transition while closing stacked
 * dialogs. Without it the dialog can stay open in the top layer with a
 * transparent backdrop that silently blocks every click on the page.
 */
const CLOSE_FALLBACK_DELAY = 500;

// Opens and closes a dialog with slide transitions.
export default class extends Controller {
  static targets = ["dialog"];

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

    this.#animateClosed(dialog, () => {
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
   * otherwise after the slide-out transition ends. Forcing a reflow before
   * adding the closing class makes the browser register the on-screen position
   * first; without it a pending layout change (such as a turbo stream replacing
   * the frame contents) can be batched with the class change and skip the
   * transition entirely.
   */
  #animateClosed(dialog, onClosed) {
    if (this.#reducedMotion()) {
      onClosed();

      return;
    }

    /*
     * Finish closing exactly once. A slide-out fires one transition event per
     * animated property, and the fallback timer can overlap them, so remove
     * both listeners and clear the timer before running onClosed. Without this
     * a dismiss would call Turbo.visit again and navigate a second time.
     */
    const finishClosing = () => {
      dialog.removeEventListener("transitionend", onTransition);
      dialog.removeEventListener("transitioncancel", onTransition);

      window.clearTimeout(fallback);

      onClosed();
    };

    /*
     * Only the dialog's own slide-out finishes closing. Ignore transition
     * events bubbling up from elements inside the dialog so an inner
     * transition can't tear the dialog down mid-animation.
     */
    const onTransition = (event) => {
      if (event.target === dialog) {
        finishClosing();
      }
    };

    dialog.addEventListener("transitionend", onTransition);
    dialog.addEventListener("transitioncancel", onTransition);

    const fallback = window.setTimeout(finishClosing, CLOSE_FALLBACK_DELAY);

    this.#forceReflow(dialog);

    dialog.classList.add("closing");
  }

  // Slide the dialog closed, then visit the given URL.
  #dismiss(dialog, url) {
    this.#animateClosed(dialog, () => {
      this.#reset(dialog);

      /*
       * Visit with the replace action so Turbo treats the same-URL navigation
       * as a page refresh and morphs the DOM, preserving scroll position
       * instead of performing a full reload.
       */
      Turbo.visit(url, { "action": "replace" });
    });
  }

  /*
   * Read offsetHeight to force a synchronous layout flush, ensuring any
   * pending style or DOM changes are applied before the next class change.
   */
  #forceReflow(dialog) {
    return dialog.offsetHeight;
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
