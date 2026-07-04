import { Controller } from "@hotwired/stimulus";

/*
 * Manages single-select of a subcategory row on the desktop budget. Checking a
 * row swaps the sidebar summary for a detail panel loaded into the category
 * frame, highlights the row, and unchecks any prior selection. Restores the
 * selection and reloads the panel when a selected row is replaced by a stream.
 */
export default class extends Controller {
  static targets = ["panelFrame", "subcategory", "summary"];

  static values = { "selectedId": String };

  subcategoryTargetConnected(box) {
    if (box.dataset.subcategoryId === this.selectedIdValue && !box.checked) {
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

      this.toggle({ "target": box });
    }
  }

  toggle(event) {
    if (event.target.checked) {
      this.subcategoryTargets.forEach((box) => {
        if (box !== event.target) {
          box.checked = false;
        }
      });
    }

    this.#updatePanel();
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

  #showPanel() {
    this.summaryTarget.classList.add("hidden");
    this.panelFrameTarget.classList.remove("hidden");
  }

  #updatePanel() {
    const checked = this.subcategoryTargets.find((box) => {
      return box.checked;
    });

    this.selectedIdValue = checked
      ? checked.dataset.subcategoryId
      : "";

    this.#highlightRows();

    if (checked) {
      this.panelFrameTarget.setAttribute("src", checked.dataset.detailUrl);
      this.#showPanel();
    } else {
      this.panelFrameTarget.removeAttribute("src");
      this.#hidePanel();
    }
  }
}
