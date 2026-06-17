import { Controller } from "@hotwired/stimulus";

const STORAGE_KEY = "budget:collapsed-sections";

export default class extends Controller {
  static values = { "id": String };

  connect() {
    if (this.#collapsedIds.has(this.idValue)) {
      this.element.classList.add("collapsed");
    }

    document.getElementById("collapsible-preload")?.remove();

    this.element.addEventListener("turbo:before-morph-attribute", this.#preserveClass);
  }

  disconnect() {
    this.element.removeEventListener("turbo:before-morph-attribute", this.#preserveClass);
  }

  toggle() {
    const collapsed = this.element.classList.toggle("collapsed"),
          ids = this.#collapsedIds;

    if (collapsed) {
      ids.add(this.idValue);
    } else {
      ids.delete(this.idValue);
    }

    this.#collapsedIds = ids;
  }

  /*
   * Cancel class morphs on this element so the client-managed collapsed state
   * survives a page morph, since connect does not re-run for a persistent
   * element. The event bubbles, so restrict the guard to this element's own
   * class attribute and let descendant rows morph their state classes normally.
   */
  #preserveClass = (event) => {
    if (event.target === this.element && event.detail.attributeName === "class") {
      event.preventDefault();
    }
  };

  get #collapsedIds() {
    return new Set(JSON.parse(localStorage.getItem(STORAGE_KEY) || "[]"));
  }

  set #collapsedIds(ids) {
    localStorage.setItem(STORAGE_KEY, JSON.stringify([...ids]));
  }
}
