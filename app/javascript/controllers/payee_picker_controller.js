import PickerController from "controllers/picker_controller";

/*
 * Manages the payee picker. Prepends a "Create" option in the rendered list
 * whenever the search query has no exact match, allowing a new payee to be
 * created inline.
 */
export default class extends PickerController {
  static targets = ["createPayeeTemplate"];

  /*
   * Return a cloned "Create" option when the query is non-empty and no exact
   * match exists in the list. Otherwise return null.
   */
  beforeRender(items, query) {
    if (query.length === 0) {
      return null;
    }

    const exactMatch = items.some((name) => {
      return name.toLowerCase() === query.toLowerCase();
    });

    if (exactMatch) {
      return null;
    }

    const node = this.createPayeeTemplateTarget.content.firstElementChild.cloneNode(true);

    node.dataset.value = query;
    node.dataset.label = query;
    node.querySelector("[data-role='label']").textContent = `Create "${query}" Payee`;

    return node;
  }
}
