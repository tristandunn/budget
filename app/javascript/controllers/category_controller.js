import { Controller } from "@hotwired/stimulus";

const ARROW_CLASSES = ["inset-y-0", "-inset-y-1", "-rotate-45", "rotate-45"],
      STORAGE_KEY   = "budget:collapsed-categories";

export default class extends Controller {
  static targets = ["arrow"];

  static values  = { "subcategoriesId": Number };

  connect() {
    if (this.#toggleStatedIds.has(this.subcategoriesIdValue)) {
      this.#toggleState();
    }
  }

  toggle() {
    this.#toggleState();
    this.#persistState();
  }

  get subcategories() {
    return document.querySelector(
      `[data-category-subcategories="${this.subcategoriesIdValue}"]`
    );
  }

  #persistState() {
    const ids         = this.#toggleStatedIds,
          isCollapsed = this.subcategories.classList.contains("hidden");

    if (isCollapsed) {
      ids.add(this.subcategoriesIdValue);
    } else {
      ids.delete(this.subcategoriesIdValue);
    }

    this.#toggleStatedIds = ids;
  }

  #toggleState() {
    this.subcategories.classList.toggle("hidden");

    ARROW_CLASSES.forEach((className) => {
      this.arrowTarget.classList.toggle(className);
    });
  }

  get #toggleStatedIds() {
    return new Set(JSON.parse(localStorage.getItem(STORAGE_KEY) || "[]"));
  }

  set #toggleStatedIds(ids) {
    localStorage.setItem(STORAGE_KEY, JSON.stringify([...ids]));
  }
}
