import PickerController from "controllers/picker_controller";

/*
 * Manages the payee picker. Inserts a "Create" option after each filter pass
 * whenever the query is non-empty and does not exactly match an existing
 * payee, allowing a new payee to be created inline.
 */
export default class extends PickerController {
  static outlets = ["category-picker"];

  static targets = ["createPayeeTemplate"];

  /*
   * Fetch the default subcategory for the selected payee and apply it on the
   * category picker outlet when one is returned. Skips the fetch when a
   * category is already selected to avoid overwriting the user's choice.
   */
  async select(event) {
    super.select(event);

    const url = event.currentTarget.dataset.previousCategoryUrl;

    if (!url || !this.hasCategoryPickerOutlet) {
      return;
    }

    if (this.categoryPickerOutlet.hiddenFieldTarget.value !== "") {
      return;
    }

    const response = await fetch(url, { "headers": { "Accept": "application/json" } });

    if (!response.ok) {
      return;
    }

    const data = await response.json();

    if (data.subcategory_id) {
      this.categoryPickerOutlet.applyValue(data.subcategory_id);
    }
  }

  /*
   * Insert, update, or remove the Create option based on the current query.
   */
  afterFilter(query) {
    const existing = this.#existingCreateOption();

    if (query.length === 0) {
      if (existing) {
        existing.remove();
      }

      return;
    }

    const exactMatch = this.itemTargets.some((item) => {
      return item.dataset.label.toLowerCase() === query.toLowerCase();
    });

    if (exactMatch) {
      if (existing) {
        existing.remove();
      }

      return;
    }

    if (existing) {
      this.#updateCreateOption(existing, query);
    } else {
      this.#insertCreateOption(query);
    }
  }

  // Return the currently inserted Create option, if any.
  #existingCreateOption() {
    return this.pickerTarget.querySelector("[data-create-option]");
  }

  // Insert a Create option for the given query at the top of the first list.
  #insertCreateOption(query) {
    const node = this.createPayeeTemplateTarget.content.firstElementChild.cloneNode(true);

    node.dataset.createOption = "";
    this.#updateCreateOption(node, query);

    const list = this.pickerTarget.querySelector("ul");

    if (list) {
      list.prepend(node);
    }
  }

  // Update an existing Create option node with the given query.
  #updateCreateOption(node, query) {
    node.dataset.value = query;
    node.dataset.label = query;
    node.querySelector("[data-role='label']").textContent = `Create "${query}" Payee`;
  }
}
