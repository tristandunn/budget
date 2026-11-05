import { Controller } from "@hotwired/stimulus";

/*
 * Manages selection of subcategory rows on the desktop budget. Checking rows
 * swaps the sidebar summary for a panel loaded into the category frame and
 * highlights the rows. A single selection loads that subcategory's detail and
 * two or more load an aggregate summary of the selection. Clicking a
 * subcategory's name selects only that row and opens its assignment input.
 * Category and select-all checkboxes check their subcategories in bulk and
 * reflect the selection with a checked, unchecked, or indeterminate state.
 */
export default class extends Controller {
  static targets = ["all", "category", "panelFrame", "subcategory", "summary"];

  static values = {
    "selectedIds": Array,
    "summaryUrl": String
  };

  connect() {
    this.#boundClearOnEscape = this.#clearOnEscape.bind(this);

    document.addEventListener("keydown", this.#boundClearOnEscape);
  }

  disconnect() {
    document.removeEventListener("keydown", this.#boundClearOnEscape);
  }

  categoryTargetConnected() {
    this.#syncSelectionStates();
  }

  subcategoryTargetConnected(checkbox) {
    if (!checkbox.checked && this.selectedIdsValue.includes(checkbox.dataset.subcategoryId)) {
      checkbox.checked = true;

      this.#highlightRows();
      this.#syncSelectionStates();
      this.panelFrameTarget.reload?.();
    }
  }

  edit(event) {
    const row  = event.target.closest("tr"),
          link = row?.querySelector("[data-controller~='inline-edit'] a");

    link?.click();
  }

  selectRow(event) {
    const row         = event.target.closest("tr"),
          rowCheckbox = row?.querySelector("[data-selection-target='subcategory']");

    if (!rowCheckbox) {
      return;
    }

    const ids = this.#selectedIds();

    if (ids.length === 1 && ids[0] === rowCheckbox.dataset.subcategoryId) {
      return;
    }

    this.subcategoryTargets.forEach((checkbox) => {
      checkbox.checked = checkbox === rowCheckbox;
    });

    this.toggle();
  }

  toggle() {
    this.#syncSelectionStates();
    this.#updatePanel();
  }

  toggleAll(event) {
    const checked = event.target.checked;

    this.subcategoryTargets.forEach((checkbox) => {
      checkbox.checked = checked;
    });

    this.#syncSelectionStates();
    this.#updatePanel();
  }

  toggleCategory(event) {
    const categoryId = event.target.dataset.categoryId,
          checked    = event.target.checked;

    this.subcategoryTargets.filter((checkbox) => {
      return checkbox.dataset.categoryId === categoryId;
    }).forEach((checkbox) => {
      checkbox.checked = checked;
    });

    this.#syncSelectionStates();
    this.#updatePanel();
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
    this.subcategoryTargets.forEach((checkbox) => {
      checkbox.checked = false;
    });

    this.#syncSelectionStates();
    this.#updatePanel();
  }

  #detailUrl(id) {
    const checkbox = this.subcategoryTargets.find((candidate) => {
      return candidate.dataset.subcategoryId === id;
    });

    return checkbox.dataset.detailUrl;
  }

  #hidePanel() {
    this.panelFrameTarget.classList.add("hidden");
    this.summaryTarget.classList.remove("hidden");
  }

  #highlightRows() {
    this.subcategoryTargets.forEach((checkbox) => {
      checkbox.closest("tr")?.toggleAttribute("data-selected", checkbox.checked);
    });
  }

  #selectedIds() {
    return this.subcategoryTargets.filter((checkbox) => {
      return checkbox.checked;
    }).map((checkbox) => {
      return checkbox.dataset.subcategoryId;
    });
  }

  #showPanel() {
    this.summaryTarget.classList.add("hidden");
    this.panelFrameTarget.classList.remove("hidden");
  }

  #summaryUrl(ids) {
    const url = new window.URL(this.summaryUrlValue, window.location.origin);

    ids.forEach((id) => {
      url.searchParams.append("ids[]", id);
    });

    return url.pathname + url.search;
  }

  #syncAllState() {
    const checkboxes   = this.subcategoryTargets;
    const checkedCount = checkboxes.filter((checkbox) => {
      return checkbox.checked;
    }).length;

    this.allTarget.checked       = checkboxes.length > 0 && checkedCount === checkboxes.length;
    this.allTarget.indeterminate = checkedCount > 0 && checkedCount < checkboxes.length;
  }

  #syncCategoryStates() {
    this.categoryTargets.forEach((category) => {
      const checkboxes = this.subcategoryTargets.filter((checkbox) => {
        return checkbox.dataset.categoryId === category.dataset.categoryId;
      });
      const checkedCount = checkboxes.filter((checkbox) => {
        return checkbox.checked;
      }).length;

      category.checked       = checkboxes.length > 0 && checkedCount === checkboxes.length;
      category.indeterminate = checkedCount > 0 && checkedCount < checkboxes.length;
    });
  }

  #syncSelectionStates() {
    this.#syncAllState();
    this.#syncCategoryStates();
  }

  #updatePanel() {
    const ids = this.#selectedIds();

    this.selectedIdsValue = ids;

    this.#highlightRows();

    if (ids.length === 0) {
      this.panelFrameTarget.removeAttribute("src");
      this.#hidePanel();
    } else if (ids.length === 1) {
      this.panelFrameTarget.setAttribute("src", this.#detailUrl(ids[0]));
      this.#showPanel();
    } else {
      this.panelFrameTarget.setAttribute("src", this.#summaryUrl(ids));
      this.#showPanel();
    }
  }
}
