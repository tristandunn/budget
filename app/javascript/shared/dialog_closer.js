/*
 * Fallback delay, in milliseconds, after which a closing element is forced
 * shut even if no transition event arrives. It is longer than the 300ms
 * slide-out transition so it only fires when the expected transitionend is
 * missing, such as when the browser cancels the transition.
 */
const CLOSE_FALLBACK_DELAY = 500;

/*
 * Tracks a single in-flight slide-out close for one element. Guards against
 * starting a second close while one is already running, and lets a reopen
 * cancel the pending close so a stale completion can't tear down or hide the
 * element after it was shown again.
 */
export default class DialogCloser {
  #cancel = null;

  /*
   * Cancel a pending close without running its completion callback. The
   * optional revert callback undoes the in-progress close state, mirroring the
   * startClose callback passed to close so this class stays agnostic about
   * which classes a caller toggles.
   */
  cancel(revert) {
    if (this.#cancel) {
      this.#cancel();
      this.#cancel = null;

      if (revert) {
        revert();
      }
    }
  }

  // Start a slide-out close unless one is already running.
  close(element, startClose, onClosed) {
    if (this.#cancel) {
      return;
    }

    this.#cancel = this.#animateClosed(element, startClose, () => {
      this.#cancel = null;

      onClosed();
    });
  }

  /*
   * Run startClose to trigger the slide-out, then run onClosed exactly once
   * when the element's own transition ends, is cancelled, or the fallback timer
   * fires. Transition events bubbling up from descendants are ignored so an
   * inner transition cannot tear the element down mid-animation. Returns a
   * teardown function that cancels the pending close without running onClosed.
   */
  #animateClosed(element, startClose, onClosed) {
    const teardown = () => {
      element.removeEventListener("transitionend", onTransition);
      element.removeEventListener("transitioncancel", onTransition);

      window.clearTimeout(fallback);
    };

    const finishClosing = () => {
      teardown();

      onClosed();
    };

    const onTransition = (event) => {
      if (event.target === element) {
        finishClosing();
      }
    };

    element.addEventListener("transitionend", onTransition);
    element.addEventListener("transitioncancel", onTransition);

    const fallback = window.setTimeout(finishClosing, CLOSE_FALLBACK_DELAY);

    void element.offsetHeight;

    startClose();

    return teardown;
  }
}
