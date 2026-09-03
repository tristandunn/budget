import { Controller } from "@hotwired/stimulus";

const COLLAPSED_ROWS =
  ".collapsed[data-collapsible-id-value] + [data-collapsible-content] " +
  "[data-transaction-selection-target='transaction']";

/*
 * Manages selection of transaction rows on the desktop register. Checking rows
 * highlights them and reveals a frame beside the Working Balance holding the
 * selected total, rendered by the server so the amount is formatted exactly
 * like every other amount on the page. The select-all checkbox checks every
 * visible row in bulk and reflects the selection with a checked, unchecked, or
 * indeterminate state.
 */
export default class extends Controller {
  static targets = ["all", "total", "transaction"];

  static values = { "summaryUrl": String };

  /*
   * Reconcile on connect rather than trusting the markup. A Turbo snapshot
   * clone carries the checked boxes and the loaded frame, but not the
   * select-all checkbox's indeterminate state, so a restored partial
   * selection reads as unchecked.
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
    return this.#selectedIds().length > 0 && !document.querySelector("dialog[open]");
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

  #selectedIds() {
    return this.transactionTargets.filter((box) => {
      return box.checked;
    }).map((box) => {
      return box.value;
    });
  }

  #summaryUrl(ids) {
    const url = new window.URL(this.summaryUrlValue, window.location.origin);

    ids.forEach((id) => {
      url.searchParams.append("ids[]", id);
    });

    return url.pathname + url.search;
  }

  #sync() {
    this.#highlightRows();
    this.#syncAllState();
    this.#updateTotal();
  }

  /*
   * Base the checked state on the visible rows alone, since select-all acts on
   * those, but fall back to indeterminate whenever anything is selected. A
   * collapsed group holding a selection would otherwise read as unchecked while
   * the total beside the Working Balance still counts it.
   */
  #syncAllState() {
    if (this.hasAllTarget) {
      const boxes        = this.#visibleBoxes(),
            checkedCount = boxes.filter((box) => {
              return box.checked;
            }).length,
            allChecked   = boxes.length > 0 && checkedCount === boxes.length;

      this.allTarget.checked       = allChecked;
      this.allTarget.indeterminate = !allChecked && this.#selectedIds().length > 0;
    }
  }

  #updateTotal() {
    const ids = this.#selectedIds();

    if (ids.length === 0) {
      this.totalTarget.setAttribute("hidden", "");
      this.totalTarget.removeAttribute("src");
      this.totalTarget.replaceChildren();
    } else {
      this.totalTarget.removeAttribute("hidden");
      this.totalTarget.setAttribute("src", this.#summaryUrl(ids));
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
