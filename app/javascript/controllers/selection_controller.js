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

  subcategoryTargetConnected(box) {
    if (!box.checked && this.selectedIdsValue.includes(box.dataset.subcategoryId)) {
      box.checked = true;

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
    const row = event.target.closest("tr"),
          box = row?.querySelector("[data-selection-target='subcategory']");

    if (!box) {
      return;
    }

    const ids = this.#selectedIds();

    if (ids.length === 1 && ids[0] === box.dataset.subcategoryId) {
      return;
    }

    this.subcategoryTargets.forEach((target) => {
      target.checked = target === box;
    });

    this.toggle();
  }

  toggle() {
    this.#syncSelectionStates();
    this.#updatePanel();
  }

  toggleAll(event) {
    const checked = event.target.checked;

    this.subcategoryTargets.forEach((box) => {
      box.checked = checked;
    });

    this.#syncSelectionStates();
    this.#updatePanel();
  }

  toggleCategory(event) {
    const categoryId = event.target.dataset.categoryId,
          checked    = event.target.checked;

    this.subcategoryTargets.filter((box) => {
      return box.dataset.categoryId === categoryId;
    }).forEach((box) => {
      box.checked = checked;
    });

    this.#syncSelectionStates();
    this.#updatePanel();
  }

  #detailUrl(id) {
    const box = this.subcategoryTargets.find((box) => {
      return box.dataset.subcategoryId === id;
    });

    return box.dataset.detailUrl;
  }

  #hidePanel() {
    this.panelFrameTarget.classList.add("hidden");
    this.summaryTarget.classList.remove("hidden");
  }

  #highlightRows() {
    this.subcategoryTargets.forEach((box) => {
      box.closest("tr")?.toggleAttribute("data-selected", box.checked);
    });
  }

  #selectedIds() {
    return this.subcategoryTargets.filter((box) => {
      return box.checked;
    }).map((box) => {
      return box.dataset.subcategoryId;
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
    const boxes = this.subcategoryTargets;
    const checkedCount = boxes.filter((box) => {
      return box.checked;
    }).length;

    this.allTarget.checked       = boxes.length > 0 && checkedCount === boxes.length;
    this.allTarget.indeterminate = checkedCount > 0 && checkedCount < boxes.length;
  }

  #syncCategoryStates() {
    this.categoryTargets.forEach((category) => {
      const boxes = this.subcategoryTargets.filter((box) => {
        return box.dataset.categoryId === category.dataset.categoryId;
      });
      const checkedCount = boxes.filter((box) => {
        return box.checked;
      }).length;

      category.checked       = boxes.length > 0 && checkedCount === boxes.length;
      category.indeterminate = checkedCount > 0 && checkedCount < boxes.length;
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
