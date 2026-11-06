import PopoverController from "controllers/popover_controller";

/*
 * Shows a popover menu anchored to its element. A click inside the menu keeps
 * it open.
 *
 * The menu opens above its anchor if it would overflow the bottom of the
 * viewport and there is more room above than below.
 *
 * The optional trigger target reflects the open state through aria-expanded.
 * Activating it while the menu is open closes the menu and cancels the
 * navigation, so an open menu is never reloaded.
 */
export default class extends PopoverController {
  static targets = ["trigger"];

  /*
   * Close the menu and cancel the navigation when the trigger is clicked while
   * the menu is open, so an open menu is never reloaded.
   */
  activate(event) {
    if (!this.closed) {
      event.preventDefault();

      this.close();
    }
  }

  // Close the menu and collapse the trigger.
  close() {
    super.close();

    this.#expand(false);
  }

  // Close the menu on a click outside it, and keep it open on a click inside.
  dismiss(event) {
    if (!this.menuTarget.contains(event.target)) {
      super.dismiss(event);
    }
  }

  // Open the menu where it fits and expand the trigger.
  open() {
    super.open();

    this.#position();
    this.#expand(true);
  }

  // Open the menu unless it is already open.
  show() {
    if (this.closed) {
      this.open();
    }
  }

  #expand(expanded) {
    if (this.hasTriggerTarget) {
      this.triggerTarget.setAttribute("aria-expanded", String(expanded));
    }
  }

  #position() {
    const menu = this.menuTarget;

    menu.dataset.placement = "below";

    const anchor = this.element.getBoundingClientRect();
    const overflows = menu.getBoundingClientRect().bottom > window.innerHeight;

    if (overflows && anchor.top > window.innerHeight - anchor.bottom) {
      menu.dataset.placement = "above";
    }
  }
}
