import PopoverController from "controllers/popover_controller";

/*
 * Shows a popover menu anchored to its element. A click inside the menu keeps
 * it open.
 *
 * The menu opens above its anchor if it would overflow the bottom of the
 * viewport and there is more room above than below. It shifts to the right if
 * it would overflow the left edge of the nearest scrolling ancestor, and its
 * arrow shifts back so it still points at the anchor.
 *
 * The optional trigger target reflects the open state through aria-expanded.
 * Activating it while the menu is open closes the menu and cancels the
 * navigation, so an open menu is never reloaded.
 */
const EDGE_GAP = 8;

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

  #clipLeft() {
    let node = this.element.parentElement;

    while (node && window.getComputedStyle(node).overflowX === "visible") {
      node = node.parentElement;
    }

    let left = 0;

    if (node) {
      left = node.getBoundingClientRect().left;
    }

    return left;
  }

  #expand(expanded) {
    if (this.hasTriggerTarget) {
      this.triggerTarget.setAttribute("aria-expanded", String(expanded));
    }
  }

  #position() {
    const menu = this.menuTarget;

    menu.dataset.placement = "below";

    this.#shift(0);

    const anchor = this.element.getBoundingClientRect();
    const overflows = menu.getBoundingClientRect().bottom > window.innerHeight;

    if (overflows && anchor.top > window.innerHeight - anchor.bottom) {
      menu.dataset.placement = "above";
    }

    this.#shift(Math.max(0, this.#clipLeft() + EDGE_GAP - menu.getBoundingClientRect().left));
  }

  #shift(distance) {
    this.menuTarget.style.setProperty("--anchored-popover-shift", `${distance}px`);
    this.menuTarget.style.setProperty("--anchored-popover-arrow-shift", `${-distance}px`);
  }
}
