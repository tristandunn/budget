import { Controller } from "@hotwired/stimulus";

/*
 * Manages selection of subcategory rows on the desktop budget. Checking rows
 * swaps the sidebar summary for a panel loaded into the category frame and
 * highlights the rows. A single selection loads that subcategory's detail and
 * two or more load an aggregate summary of the selection.
 */
export default class extends Controller {
  static targets = ["panelFrame", "subcategory", "summary"];

  static values = {
    "selectedIds": Array,
    "summaryUrl": String
  };

  subcategoryTargetConnected(box) {
    if (!box.checked && this.selectedIdsValue.includes(box.dataset.subcategoryId)) {
      box.checked = true;

      this.#highlightRows();
      this.panelFrameTarget.reload?.();
    }
  }

  selectRow(event) {
    const row = event.target.closest("tr"),
          box = row?.querySelector("[data-selection-target='subcategory']");

    if (box && !box.checked) {
      box.checked = true;

      this.toggle();
    }
  }

  toggle() {
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
