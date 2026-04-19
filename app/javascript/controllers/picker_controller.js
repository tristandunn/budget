import { Controller } from "@hotwired/stimulus";

/*
 * Manages a generic search-and-select picker panel within a dialog. Subclasses
 * can override `beforeRender` to inject an extra leading list item, or
 * `groupFor` to render items sectioned under group headers.
 */
export default class extends Controller {
  static targets = ["display", "hiddenField", "icon", "list", "picker", "search"];

  static values = { "url": String };

  // Show the picker panel and fetch items.
  open() {
    this.pickerTarget.classList.remove("hidden");

    if (!this.#reducedMotion()) {
      void this.pickerTarget.offsetHeight;
    }

    this.pickerTarget.classList.add("open");

    return this.#fetchItems().then((items) => {
      this.#renderList(items, "");
      this.searchTarget.value = "";
      this.searchTarget.focus();
    });
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

  // Filter the item list based on the search input.
  filter() {
    const trimmed = this.searchTarget.value.trim();

    return this.#fetchItems().then((items) => {
      const filtered = trimmed.length > 0
        ? items.filter((item) => {
          return this.labelFor(item).toLowerCase().
            includes(trimmed.toLowerCase());
        })
        : items;

      this.#renderList(filtered, trimmed);
    });
  }

  // Select an item and return to the form.
  select(event) {
    const target = event.currentTarget;

    this.hiddenFieldTarget.value = target.dataset.value;
    this.displayTarget.textContent = target.dataset.label;
    this.displayTarget.classList.remove("text-gray-400");
    this.displayTarget.classList.add("text-gray-800");
    this.iconTarget.classList.remove("text-taupe-400");
    this.iconTarget.classList.add("text-indigo-600");

    this.#closePanel();
  }

  /*
   * Subclass hook returning an optional node to prepend to the rendered list,
   * such as a "Create" option. Defaults to no extra node. Subclasses receive
   * the list items and the current search query.
   */
  beforeRender() {
    return null;
  }

  /*
   * Subclass hook returning a group header string for the given item, or null
   * when the picker renders a flat list. When non-null, consecutive items
   * sharing a header appear together under a bold label in their own white
   * container.
   */
  groupFor() {
    return null;
  }

  // Return the display label for the given item.
  labelFor(item) {
    if (typeof item === "string") {
      return item;
    } else {
      return item.name;
    }
  }

  // Return the form value for the given item.
  valueFor(item) {
    if (typeof item === "string") {
      return item;
    } else {
      return String(item.id);
    }
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

  /*
   * Fetch items from the server, caching after the first request. Returns an
   * empty list and skips caching on failure so the next action can retry.
   */
  #fetchItems() {
    if (this.cachedItems) {
      return Promise.resolve(this.cachedItems);
    }

    return fetch(this.urlValue, {
      "headers": { "Accept": "application/json" }
    }).
      then((response) => {
        if (!response.ok) {
          throw new Error(`Unexpected response: ${response.status}`);
        }

        return response.json();
      }).
      then((items) => {
        this.cachedItems = items;

        return items;
      }).
      catch(() => {
        return [];
      });
  }

  // Build an `<li>` element for the given item.
  #itemNode(item) {
    const label = this.labelFor(item);
    const node = document.createElement("li");
    node.className = "px-4 py-3 text-base cursor-pointer";
    node.dataset.action = `click->${this.identifier}#select`;
    node.dataset.value = this.valueFor(item);
    node.dataset.label = label;
    node.textContent = label;

    return node;
  }

  // Return whether the user prefers reduced motion.
  #reducedMotion() {
    return window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  }

  /*
   * Render the item list into the list target. When any item reports a group,
   * render as sections, each with a header element above its own white rounded
   * list. Otherwise render a single flat white list.
   */
  #renderList(items, query) {
    const beforeNode = this.beforeRender(items, query);
    const groups = this.#groupItems(items);
    const grouped = groups.some((group) => {
      return group.header !== null;
    });

    this.listTarget.replaceChildren();
    this.listTarget.classList.toggle("space-y-4", grouped);

    groups.forEach((group, index) => {
      const list = document.createElement("ul");
      list.className = "bg-white rounded-xl divide-y divide-taupe-200";

      if (index === 0 && beforeNode) {
        list.appendChild(beforeNode);
      }

      for (const item of group.items) {
        list.appendChild(this.#itemNode(item));
      }

      if (group.header === null) {
        this.listTarget.appendChild(list);
      } else {
        const section = document.createElement("div");
        const header = document.createElement("h3");
        header.className = "px-1 pb-1 text-sm font-semibold text-gray-800";
        header.textContent = group.header;
        section.appendChild(header);
        section.appendChild(list);
        this.listTarget.appendChild(section);
      }
    });

    if (groups.length === 0 && beforeNode) {
      const list = document.createElement("ul");
      list.className = "bg-white rounded-xl divide-y divide-taupe-200";
      list.appendChild(beforeNode);
      this.listTarget.appendChild(list);
    }
  }

  // Return items grouped into ordered sections by `groupFor`.
  #groupItems(items) {
    const groups = [];

    for (const item of items) {
      const header = this.groupFor(item);
      const current = groups[groups.length - 1];

      if (current && current.header === header) {
        current.items.push(item);
      } else {
        groups.push({ "header": header,
          "items": [item] });
      }
    }

    return groups;
  }
}
