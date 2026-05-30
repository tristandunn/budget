import PickerController from "controllers/picker_controller";

/*
 * Manages the category picker. Rebuilds a suggested group at the top of the
 * list whenever a payee is selected, cloning the matching category items so
 * the suggestions share the originals' selection behavior and amounts.
 */
export default class extends PickerController {
  static targets = ["groups"];

  /*
   * Replace the suggested group with one built from the given subcategory IDs,
   * in order. Removes the group when none of the IDs match a category item.
   */
  applySuggestions(ids) {
    this.#existingSuggestedGroup()?.remove();

    const sources = this.#categoryItemsByValue();
    const items   = ids.filter((id) => {
      return sources.has(id);
    }).map((id) => {
      return sources.get(id);
    });

    if (items.length > 0) {
      this.groupsTarget.prepend(this.#buildSuggestedGroup(items));
    }
  }

  // Build a suggested section from clones of the given category items.
  #buildSuggestedGroup(items) {
    const section = document.createElement("section");

    section.dataset.categoryPickerTarget = "group";
    section.dataset.suggestedGroup       = "";

    const heading = document.createElement("h3");

    heading.className   = "px-1 pb-1 text-sm font-semibold text-taupe-800";
    heading.textContent = this.groupsTarget.dataset.suggestedLabel;

    const list = document.createElement("ul");

    list.className = "bg-white rounded-xl divide-y divide-taupe-200";
    list.setAttribute("role", "listbox");

    for (const item of items) {
      list.append(item.cloneNode(true));
    }

    section.append(heading, list);

    return section;
  }

  /*
   * Map each canonical category item to its value. The suggested group is
   * removed before this runs, so every remaining item is a canonical source.
   */
  #categoryItemsByValue() {
    const items = this.groupsTarget.querySelectorAll("[data-category-picker-target='item']");

    return new Map(Array.from(items, (item) => {
      return [item.dataset.value, item];
    }));
  }

  // Return the current suggested group section, if any.
  #existingSuggestedGroup() {
    return this.groupsTarget.querySelector("[data-suggested-group]");
  }
}
