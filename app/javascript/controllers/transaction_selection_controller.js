import { Controller } from "@hotwired/stimulus";

const COLLAPSED_ROWS = ".collapsed[data-collapsible-id-value] + * " +
  "[data-transaction-selection-target='transaction']";

/*
 * Manages selection of transaction rows on the desktop register. Checking rows
 * highlights them and reveals a frame beside the working balance holding the
 * selected total, rendered by the server so the amount is formatted exactly
 * like every other amount on the page. The select-all checkbox checks every
 * visible row in bulk and reflects the selection with a checked, unchecked, or
 * indeterminate state.
 */
export default class extends Controller {
  static targets = ["all", "total", "transaction"];

  static values = { "summaryUrl": String };

  /*
   * Reconcile on connect rather than trusting the markup. A Turbo snapshot is
   * cloned, which carries the selected attributes and the loaded frame over
   * but not the checkedness of the boxes, so a restored page would otherwise
   * show a total for a selection that no longer exists.
   */
  connect() {
    this.#boundClearOnEscape = this.#clearOnEscape.bind(this);

    document.addEventListener("keydown", this.#boundClearOnEscape);

    this.#sync();
  }

  disconnect() {
    document.removeEventListener("keydown", this.#boundClearOnEscape);
  }

  toggle() {
    this.#sync();
  }

  toggleAll(event) {
    const checked = event.target.checked;

    this.#visibleBoxes().forEach((box) => {
      box.checked = checked;
    });

    this.#sync();
  }

  #boundClearOnEscape = null;

  #clearable() {
    return this.#selectedBoxes().length > 0 && !document.querySelector("dialog[open]");
  }

  #clearOnEscape(event) {
    if (event.key === "Escape" && this.#clearable()) {
      this.#clearSelection();
    }
  }

  #clearSelection() {
    this.transactionTargets.forEach((box) => {
      box.checked = false;
    });

    this.#sync();
  }

  #highlightRows() {
    this.transactionTargets.forEach((box) => {
      box.closest("tr")?.toggleAttribute("data-selected", box.checked);
    });
  }

  #selectedBoxes() {
    return this.transactionTargets.filter((box) => {
      return box.checked;
    });
  }

  #summaryUrl(boxes) {
    const url = new window.URL(this.summaryUrlValue, window.location.origin);

    boxes.forEach((box) => {
      url.searchParams.append("ids[]", box.value);
    });

    return url.pathname + url.search;
  }

  #sync() {
    this.#highlightRows();
    this.#syncAllState();
    this.#updateTotal();
  }

  /*
   * Reflect only the visible rows, since a collapsed group is what select-all
   * acts on.
   */
  #syncAllState() {
    if (this.hasAllTarget) {
      const boxes        = this.#visibleBoxes(),
            checkedCount = boxes.filter((box) => {
              return box.checked;
            }).length;

      this.allTarget.checked       = boxes.length > 0 && checkedCount === boxes.length;
      this.allTarget.indeterminate = checkedCount > 0 && checkedCount < boxes.length;
    }
  }

  #updateTotal() {
    const boxes = this.#selectedBoxes();

    this.totalTarget.toggleAttribute("hidden", boxes.length === 0);

    if (boxes.length === 0) {
      this.totalTarget.removeAttribute("src");
      this.totalTarget.replaceChildren();
    } else {
      this.totalTarget.setAttribute("src", this.#summaryUrl(boxes));
    }
  }

  /*
   * Return the boxes the user can actually see. Rows in a collapsed group stay
   * in the document, so select-all would otherwise reach rows that are not on
   * screen.
   */
  #visibleBoxes() {
    const collapsed = new Set(this.element.querySelectorAll(COLLAPSED_ROWS));

    return this.transactionTargets.filter((box) => {
      return !collapsed.has(box);
    });
  }
}
