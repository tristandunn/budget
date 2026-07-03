import { Controller } from "@hotwired/stimulus";

/*
 * Filters a list of payees by a case-insensitive substring match on the search
 * input. Listens for the dialog:close event fired by the dialog-dismisser so
 * the search clears after the rename dialog updates the list via turbo-stream.
 */
export default class extends Controller {
  static targets = ["empty", "item", "search"];

  connect() {
    this.#boundReset = this.reset.bind(this);

    document.addEventListener("dialog:close", this.#boundReset);

    this.reset();
  }

  disconnect() {
    document.removeEventListener("dialog:close", this.#boundReset);
  }

  // Show only items whose label contains the query; an empty query shows all items.
  filter() {
    if (!this.hasSearchTarget) {
      return;
    }

    const trimmed = this.searchTarget.value.trim();
    const isEmpty = trimmed.length === 0;
    const query   = trimmed.toLowerCase();

    let visible = false;

    for (const item of this.itemTargets) {
      const matches = isEmpty || item.dataset.label.toLowerCase().includes(query);

      item.classList.toggle("hidden", !matches);

      visible ||= matches;
    }

    if (this.hasEmptyTarget) {
      this.emptyTarget.classList.toggle("hidden", isEmpty || this.itemTargets.length === 0 || visible);
    }
  }

  // Clear the search and re-run the filter so a refreshed list shows everything.
  reset() {
    if (this.hasSearchTarget) {
      this.searchTarget.value = "";
    }

    this.filter();
  }

  #boundReset = null;
}
