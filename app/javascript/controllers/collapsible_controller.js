import { Controller } from "@hotwired/stimulus";

const STORAGE_KEY = "budget:collapsed-sections";

export default class extends Controller {
  static values = { "id": String };

  connect() {
    if (this.#collapsedIds.has(this.idValue)) {
      this.element.classList.add("collapsed");
    }

    document.getElementById("collapsible-preload")?.remove();
  }

  toggle() {
    this.element.classList.toggle("collapsed");
    this.#persistState();
  }

  #persistState() {
    const ids = this.#collapsedIds;

    if (this.element.classList.contains("collapsed")) {
      ids.add(this.idValue);
    } else {
      ids.delete(this.idValue);
    }

    this.#collapsedIds = ids;
  }

  get #collapsedIds() {
    return new Set(JSON.parse(localStorage.getItem(STORAGE_KEY) || "[]"));
  }

  set #collapsedIds(ids) {
    localStorage.setItem(STORAGE_KEY, JSON.stringify([...ids]));
  }
}
