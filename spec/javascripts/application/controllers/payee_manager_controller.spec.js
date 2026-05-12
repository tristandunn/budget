import PayeeManagerController from "@app/controllers/payee_manager_controller.js";

describe("PayeeManagerController", () => {
  let element, empty, instance, items, search;

  beforeEach(() => {
    search = document.createElement("input");
    search.type = "search";

    items = ["Coffee", "Groceries", "Gas"].map((label) => {
      const item = document.createElement("li");

      item.dataset.label = label;

      return item;
    });

    empty = document.createElement("p");
    empty.classList.add("hidden");

    element = document.createElement("div");
    element.appendChild(search);
    items.forEach((item) => {
      return element.appendChild(item);
    });
    element.appendChild(empty);

    instance = new PayeeManagerController({ "scope": { element } });
    instance.searchTarget = search;
    instance.hasSearchTarget = true;
    instance.itemTargets = items;
    instance.emptyTarget = empty;
    instance.hasEmptyTarget = true;
  });

  afterEach(() => {
    instance.disconnect();
  });

  describe("#connect", () => {
    it("clears the search input", () => {
      search.value = "stale";

      instance.connect();

      expect(search.value).to.eq("");
    });

    it("shows all items", () => {
      items.forEach((item) => {
        return item.classList.add("hidden");
      });

      instance.connect();

      items.forEach((item) => {
        return expect(item.classList.contains("hidden")).to.eq(false);
      });
    });
  });

  describe("#disconnect", () => {
    it("stops resetting on dialog:close", () => {
      instance.connect();
      instance.disconnect();

      search.value = "stale";

      document.dispatchEvent(new window.CustomEvent("dialog:close"));

      expect(search.value).to.eq("stale");
    });
  });

  describe("#filter", () => {
    it("hides items that do not match the query", () => {
      search.value = "co";

      instance.filter();

      expect(items[0].classList.contains("hidden")).to.eq(false);
      expect(items[1].classList.contains("hidden")).to.eq(true);
      expect(items[2].classList.contains("hidden")).to.eq(true);
    });

    it("matches case-insensitively", () => {
      search.value = "GROCERIES";

      instance.filter();

      expect(items[1].classList.contains("hidden")).to.eq(false);
    });

    it("shows all items when the query is empty", () => {
      items.forEach((item) => {
        return item.classList.add("hidden");
      });

      search.value = "  ";

      instance.filter();

      items.forEach((item) => {
        return expect(item.classList.contains("hidden")).to.eq(false);
      });
    });

    it("shows the empty message when items exist but none match the query", () => {
      search.value = "zzz";

      instance.filter();

      expect(empty.classList.contains("hidden")).to.eq(false);
    });

    it("hides the empty message when items match", () => {
      empty.classList.remove("hidden");
      search.value = "co";

      instance.filter();

      expect(empty.classList.contains("hidden")).to.eq(true);
    });

    it("hides the empty message when the search is empty", () => {
      empty.classList.remove("hidden");
      search.value = "";

      instance.filter();

      expect(empty.classList.contains("hidden")).to.eq(true);
    });

    it("hides the empty message when there are no items to filter", () => {
      empty.classList.remove("hidden");
      instance.itemTargets = [];
      search.value = "zzz";

      instance.filter();

      expect(empty.classList.contains("hidden")).to.eq(true);
    });

    context("when the search target is missing", () => {
      it("returns without filtering items", () => {
        instance.hasSearchTarget = false;
        items.forEach((item) => {
          return item.classList.add("hidden");
        });

        instance.filter();

        items.forEach((item) => {
          return expect(item.classList.contains("hidden")).to.eq(true);
        });
      });
    });
  });

  describe("#reset", () => {
    it("clears the search input", () => {
      search.value = "stale";

      instance.reset();

      expect(search.value).to.eq("");
    });

    it("shows all items after the search is cleared", () => {
      search.value = "stale";
      items.forEach((item) => {
        return item.classList.add("hidden");
      });

      instance.reset();

      items.forEach((item) => {
        return expect(item.classList.contains("hidden")).to.eq(false);
      });
    });

    context("when the search target is missing", () => {
      it("does not raise", () => {
        instance.hasSearchTarget = false;

        expect(() => {
          return instance.reset();
        }).not.to.throw();
      });
    });
  });

  describe("on dialog:close", () => {
    it("clears the search input", () => {
      instance.connect();

      search.value = "stale";

      document.dispatchEvent(new window.CustomEvent("dialog:close"));

      expect(search.value).to.eq("");
    });
  });
});
