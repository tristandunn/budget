import PickerController from "controllers/picker_controller";

/*
 * Inserts a "Create" option in the payee picker after each filter pass
 * whenever the query is non-empty and does not exactly match an existing
 * payee, allowing a new payee to be created inline. Payees with a word that
 * starts with the query are listed before other matches.
 */
export default class extends PickerController {
  static outlets = ["account-picker", "category-picker"];

  static targets = ["createPayeeTemplate", "memo"];

  #originalOrder = new Map();

  /*
   * Fetch the defaults for the selected payee and apply them on the account
   * and category picker outlets: apply the previous account when the account
   * picker is empty, refresh the suggested group on the category picker, then
   * apply the previous subcategory when the category picker is empty. Also fill
   * the memo field with the payee's consistent memo when it is empty. Skips the
   * fetch only when there is nothing to do, meaning the account picker is
   * already filled or absent, the memo is filled or absent, and there is no
   * category picker whose suggestions need refreshing. Re-checks emptiness
   * after the fetch resolves so a value the user entered while the request was
   * in flight is preserved.
   */
  async select(event) {
    super.select(event);

    const url = event.currentTarget.dataset.defaultsUrl;

    if (!url) {
      return;
    }

    if (!this.#accountPickerEmpty() && !this.#memoEmpty() && !this.hasCategoryPickerOutlet) {
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

    if (this.hasCategoryPickerOutlet) {
      this.categoryPickerOutlet.applySuggestions(data.suggested_subcategory_ids || []);
    }

    if (data.subcategory_id && this.#categoryPickerEmpty()) {
      this.categoryPickerOutlet.applyValue(data.subcategory_id);
    }

    if (data.memo && this.#memoEmpty()) {
      this.memoTarget.value = data.memo;
    }
  }

  /*
   * Order the payees by match quality, then insert, update, or remove the
   * create option based on the current query.
   */
  afterFilter(query) {
    this.#sortItems(query);

    const existing   = this.#existingCreateOption();
    const exactMatch = query.length > 0 && this.itemTargets.some((item) => {
      return item.dataset.label.toLowerCase() === query.toLowerCase();
    });

    if (query.length === 0 || exactMatch) {
      existing?.remove();
    } else if (existing) {
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

  // Return whether the memo field exists and has no value entered.
  #memoEmpty() {
    return this.hasMemoTarget && this.memoTarget.value === "";
  }

  // Return 0 when a word in the item label starts with the query, otherwise 1.
  #rank(item, query) {
    return query.length > 0 && this.#startsWord(item.dataset.label, query)
      ? 0
      : 1;
  }

  /*
   * Move payees with a word starting with the query ahead of the others,
   * preserving the original order within each group. The original order is
   * recorded on first use, before any reordering has happened. The DOM is
   * only touched when the sorted order differs from the current order.
   */
  #sortItems(query) {
    const current = this.itemTargets;
    const needle  = query.toLowerCase();

    for (const item of current) {
      if (!this.#originalOrder.has(item)) {
        this.#originalOrder.set(item, this.#originalOrder.size);
      }
    }

    const ranks  = new Map(current.map((item) => {
      return [item, this.#rank(item, needle)];
    }));

    const sorted = [...current].sort((first, second) => {
      return ranks.get(first) - ranks.get(second) ||
        this.#originalOrder.get(first) - this.#originalOrder.get(second);
    });

    const changed = sorted.some((item, index) => {
      return item !== current[index];
    });

    if (changed) {
      for (const item of sorted) {
        item.parentElement.appendChild(item);
      }
    }
  }

  // Return whether any word in the label starts with the lowercase query.
  #startsWord(label, query) {
    const text = label.toLowerCase();

    let index = text.indexOf(query);

    while (index !== -1) {
      if (index === 0 || !(/[\p{L}\p{N}]/u).test(text[index - 1])) {
        return true;
      }

      index = text.indexOf(query, index + 1);
    }

    return false;
  }

  // Update an existing Create option node with the given query.
  #updateCreateOption(node, query) {
    node.dataset.value = query;
    node.dataset.label = query;
    node.querySelector("[data-role='label']").textContent = `Create "${query}" Payee`;
  }
}
