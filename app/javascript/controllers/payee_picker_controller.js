import { Controller } from "@hotwired/stimulus";

// Manages a payee picker panel within the transaction dialog.
export default class extends Controller {
  static targets = ["createPayeeTemplate", "display", "hiddenField", "icon", "list", "picker", "search"];

  static values = { "url": String };

  // Show the picker panel and fetch payees.
  open() {
    this.pickerTarget.classList.remove("hidden");

    if (!this.#reducedMotion()) {
      void this.pickerTarget.offsetHeight;
    }

    this.pickerTarget.classList.add("open");

    return this.#fetchPayees().then((payees) => {
      this.#renderList(payees, "");
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

  // Filter the payee list based on the search input.
  filter() {
    const trimmed = this.searchTarget.value.trim();

    return this.#fetchPayees().then((payees) => {
      const filtered = trimmed.length > 0
        ? payees.filter((name) => {
          return name.toLowerCase().includes(trimmed.toLowerCase());
        })
        : payees;

      this.#renderList(filtered, trimmed);
    });
  }

  // Select a payee and return to the form.
  select(event) {
    const name = event.currentTarget.dataset.value;

    this.hiddenFieldTarget.value = name;
    this.displayTarget.textContent = name;
    this.displayTarget.classList.remove("text-gray-400");
    this.displayTarget.classList.add("text-gray-800");
    this.iconTarget.classList.remove("text-taupe-400");
    this.iconTarget.classList.add("text-indigo-600");

    this.#closePanel();
  }

  // Clone the create template and fill in the payee name.
  #createOption(name) {
    const item = this.createPayeeTemplateTarget.content.firstElementChild.cloneNode(true);

    item.dataset.value = name;
    item.querySelector("[data-role='label']").textContent = `Create "${name}" Payee`;

    return item;
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
   * Fetch payees from the server, caching after the first request. Returns an
   * empty list and skips caching on failure so the next action can retry.
   */
  #fetchPayees() {
    if (this.cachedPayees) {
      return Promise.resolve(this.cachedPayees);
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
      then((payees) => {
        this.cachedPayees = payees;

        return payees;
      }).
      catch(() => {
        return [];
      });
  }

  // Return whether the user prefers reduced motion.
  #reducedMotion() {
    return window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  }

  // Render the payee list, prepending a "Create" option when needed.
  #renderList(payees, query) {
    const items = [];

    if (query.length > 0) {
      const exactMatch = payees.some(
        (name) => {
          return name.toLowerCase() === query.toLowerCase();
        }
      );

      if (!exactMatch) {
        items.push(this.#createOption(query));
      }
    }

    for (const name of payees) {
      const item = document.createElement("li");
      item.className = "px-4 py-3 text-base cursor-pointer";
      item.dataset.action = "click->payee-picker#select";
      item.dataset.value = name;
      item.textContent = name;
      items.push(item);
    }

    this.listTarget.replaceChildren(...items);
  }
}
