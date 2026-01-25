import { Controller } from "@hotwired/stimulus";

const ARROW_CLASSES = ["inset-y-0", "-inset-y-1", "-rotate-45", "rotate-45"],
      STORAGE_KEY   = "budget:collapsed-sections";

export default class extends Controller {
  static targets = ["arrow"];

  static values = { "id": String };

  connect() {
    if (this.#collapsedIds.has(this.idValue)) {
      this.#toggleState();
    }
  }

  toggle() {
    this.#toggleState();
    this.#persistState();
  }

  get content() {
    return document.querySelector(`[data-collapsible-content="collapsible-${this.idValue}"]`);
  }

  #persistState() {
    const ids         = this.#collapsedIds,
          isCollapsed = this.content.classList.contains("hidden");

    if (isCollapsed) {
      ids.add(this.idValue);
    } else {
      ids.delete(this.idValue);
    }

    this.#collapsedIds = ids;
  }

  #toggleState() {
    this.content.classList.toggle("hidden");

    ARROW_CLASSES.forEach((className) => {
      this.arrowTarget.classList.toggle(className);
    });
  }

  get #collapsedIds() {
    return new Set(JSON.parse(localStorage.getItem(STORAGE_KEY) || "[]"));
  }

  set #collapsedIds(ids) {
    localStorage.setItem(STORAGE_KEY, JSON.stringify([...ids]));
  }
}
