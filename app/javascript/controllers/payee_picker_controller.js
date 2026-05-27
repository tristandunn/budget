import PickerController from "controllers/picker_controller";

/*
 * Manages the payee picker. Inserts a "Create" option after each filter pass
 * whenever the query is non-empty and does not exactly match an existing
 * payee, allowing a new payee to be created inline.
 */
export default class extends PickerController {
  static outlets = ["account-picker", "category-picker"];

  static targets = ["createPayeeTemplate"];

  /*
   * Fetch the defaults for the selected payee and apply them on the account
   * and category picker outlets when each is empty. Re-checks emptiness after
   * the fetch resolves so a value the user picked while the request was in
   * flight is preserved.
   */
  async select(event) {
    super.select(event);

    const url = event.currentTarget.dataset.defaultsUrl;

    if (!url) {
      return;
    }

    if (!this.#accountPickerEmpty() && !this.#categoryPickerEmpty()) {
      return;
    }

    const response = await fetch(url, { "headers": { "Accept": "application/json" } });

    if (!response.ok) {
      return;
    }

    const data = await response.json();

    if (data.account_id && this.#accountPickerEmpty()) {
      this.accountPickerOutlet.applyValue(data.account_id);
    }

    if (data.subcategory_id && this.#categoryPickerEmpty()) {
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

  // Return whether the account picker outlet exists and has no value selected.
  #accountPickerEmpty() {
    return this.hasAccountPickerOutlet &&
      this.accountPickerOutlet.hiddenFieldTarget.value === "";
  }

  // Return whether the category picker outlet exists and has no value selected.
  #categoryPickerEmpty() {
    return this.hasCategoryPickerOutlet &&
      this.categoryPickerOutlet.hiddenFieldTarget.value === "";
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
