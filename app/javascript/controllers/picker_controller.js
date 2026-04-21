import { Controller } from "@hotwired/stimulus";

/*
 * Manages a search-and-select picker panel built from server-rendered items.
 * Subclasses can override `afterFilter` to modify the list after each filter
 * pass.
 */
export default class extends Controller {
  static targets = ["display", "group", "hiddenField", "icon", "item", "picker", "search"];

  // Show the picker panel and reset the search input.
  open() {
    this.pickerTarget.classList.remove("hidden");

    if (!this.#reducedMotion()) {
      void this.pickerTarget.offsetHeight;
    }

    this.pickerTarget.classList.add("open");
    this.searchTarget.value = "";
    this.searchTarget.focus();
    this.filter();
  }

  // Open the picker from a keyboard activation on the trigger.
  openOnKey(event) {
    if (event.key === "Enter" || event.key === " ") {
      event.preventDefault();

      this.open();
    }
  }

  // Animate the picker closed and return to the form.
  back() {
    this.#closePanel();
  }

  // Show only items whose label contains the query; an empty query shows all items.
  filter() {
    const trimmed = this.searchTarget.value.trim();
    const query   = trimmed.toLowerCase();

    for (const item of this.itemTargets) {
      const matches = trimmed.length === 0 ||
        item.dataset.label.toLowerCase().includes(query);

      item.classList.toggle("hidden", !matches);
    }

    for (const group of this.groupTargets) {
      const hasVisible = this.itemTargets.some((item) => {
        return group.contains(item) && !item.classList.contains("hidden");
      });

      group.classList.toggle("hidden", !hasVisible);
    }

    this.afterFilter(trimmed);
  }

  // Select an item and return to the form.
  select(event) {
    const target = event.currentTarget;

    this.#applySelection(target.dataset.value, target.dataset.label);
  }

  // Select an item whose label exactly matches the search input on Enter.
  selectOnKey(event) {
    if (event.key !== "Enter" || event.isComposing) {
      return;
    }

    event.preventDefault();

    const trimmed = this.searchTarget.value.trim();

    if (trimmed.length === 0) {
      return;
    }

    const query = trimmed.toLowerCase();
    const match = this.itemTargets.find((item) => {
      return item.dataset.label.toLowerCase() === query;
    });

    if (match) {
      this.#applySelection(match.dataset.value, match.dataset.label);
    }
  }

  /*
   * Subclass hook invoked after each filter pass. Subclasses receive the
   * trimmed query. The default implementation is a no-op.
   */
  afterFilter() {}

  // Apply a selection to the form and close the picker.
  #applySelection(value, label) {
    this.hiddenFieldTarget.value      = value;
    this.displayTarget.textContent    = label;
    this.displayTarget.classList.remove("text-gray-400");
    this.displayTarget.classList.add("text-gray-800");
    this.iconTarget.classList.remove("text-taupe-400");
    this.iconTarget.classList.add("text-indigo-600");

    for (const item of this.itemTargets) {
      const selected = item.dataset.value === value;

      item.setAttribute("aria-selected", selected);
      item.classList.toggle("text-indigo-600", selected);
      item.classList.toggle("font-medium", selected);
    }

    this.#closePanel();
  }

  // Animate the picker panel closed.
  #closePanel() {
    if (this.#reducedMotion()) {
      this.pickerTarget.classList.remove("open");
      this.pickerTarget.classList.add("hidden");

      return;
    }

    this.pickerTarget.addEventListener(
      "transitionend",
      () => {
        this.pickerTarget.classList.remove("closing");
        this.pickerTarget.classList.add("hidden");
      },
      { "once": true }
    );

    this.pickerTarget.classList.remove("open");
    this.pickerTarget.classList.add("closing");
  }

  // Return whether the user prefers reduced motion.
  #reducedMotion() {
    return window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  }
}
