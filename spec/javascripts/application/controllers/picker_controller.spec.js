import PickerController from "@app/controllers/picker_controller.js";

describe("PickerController", () => {
  let controller, display, hiddenField, icon, list, picker, search;

  beforeEach(() => {
    picker = document.createElement("div");
    picker.classList.add("hidden");

    search = document.createElement("input");
    search.type = "search";

    list = document.createElement("div");

    hiddenField = document.createElement("input");
    hiddenField.type = "hidden";

    display = document.createElement("span");
    display.classList.add("text-gray-400");

    icon = document.createElement("svg");
    icon.classList.add("text-taupe-400");

    controller = new PickerController({
      "scope": {
        "element": document.createElement("div"),
        "identifier": "test-picker"
      }
    });
    controller.pickerTarget = picker;
    controller.searchTarget = search;
    controller.listTarget = list;
    controller.hiddenFieldTarget = hiddenField;
    controller.displayTarget = display;
    controller.iconTarget = icon;
    controller.urlValue = "/items";

    global.fetch = sinon.fake.resolves({
      "json": () => {
        return Promise.resolve([
          { "id": 1,
            "name": "Alpha" },
          { "id": 2,
            "name": "Beta" }
        ]);
      },
      "ok": true
    });

    sinon.stub(window, "matchMedia").returns({ "matches": true });
  });

  afterEach(() => {
    delete global.fetch;
  });

  describe("#open", () => {
    it("shows the picker", async () => {
      await controller.open();

      expect(picker.classList.contains("hidden")).to.be.false;
      expect(picker.classList.contains("open")).to.be.true;
    });

    it("fetches items and renders them in a single flat list", async () => {
      await controller.open();

      expect(list.children).to.have.lengthOf(1);
      expect(list.children[0].tagName).to.eq("UL");
      expect(list.children[0].children).to.have.lengthOf(2);
      expect(list.children[0].children[0].textContent).to.eq("Alpha");
      expect(list.children[0].children[1].textContent).to.eq("Beta");
    });

    it("sets data attributes on each item for select", async () => {
      await controller.open();

      const item = list.querySelector("li");

      expect(item.dataset.value).to.eq("1");
      expect(item.dataset.label).to.eq("Alpha");
      expect(item.dataset.action).to.eq("click->test-picker#select");
    });

    it("clears and focuses the search input", async () => {
      search.value = "old query";
      document.body.appendChild(search);

      await controller.open();

      expect(search.value).to.eq("");
      expect(document.activeElement).to.eq(search);

      document.body.removeChild(search);
    });

    it("forces a reflow when motion is enabled", async () => {
      window.matchMedia.returns({ "matches": false });

      await controller.open();

      expect(picker.classList.contains("open")).to.be.true;
    });

    it("caches items after the first fetch", async () => {
      await controller.open();
      await controller.open();

      expect(global.fetch).to.have.been.calledOnce;
    });

    it("renders an empty list and retries after a failed fetch", async () => {
      global.fetch = sinon.fake.rejects(new Error("boom"));

      await controller.open();

      expect(list.children).to.have.lengthOf(0);

      await controller.open();

      expect(global.fetch).to.have.been.calledTwice;
    });

    it("renders an empty list when the response is not ok", async () => {
      global.fetch = sinon.fake.resolves({
        "ok": false,
        "status": 500
      });

      await controller.open();

      expect(list.children).to.have.lengthOf(0);
    });
  });

  describe("#open with string items", () => {
    beforeEach(() => {
      global.fetch = sinon.fake.resolves({
        "json": () => {
          return Promise.resolve(["Whole Foods", "Coffee Shop"]);
        },
        "ok": true
      });
    });

    it("uses the string as both label and value", async () => {
      await controller.open();

      const items = list.querySelectorAll("li");

      expect(items[0].dataset.value).to.eq("Whole Foods");
      expect(items[0].dataset.label).to.eq("Whole Foods");
      expect(items[0].textContent).to.eq("Whole Foods");
    });
  });

  describe("#openOnKey", () => {
    beforeEach(() => {
      sinon.stub(controller, "open");
    });

    it("opens the picker when Enter is pressed", () => {
      const event = {
        "key": "Enter",
        "preventDefault": sinon.fake()
      };

      controller.openOnKey(event);

      expect(event.preventDefault).to.have.been.called;
      expect(controller.open).to.have.been.called;
    });

    it("opens the picker when Space is pressed", () => {
      const event = {
        "key": " ",
        "preventDefault": sinon.fake()
      };

      controller.openOnKey(event);

      expect(event.preventDefault).to.have.been.called;
      expect(controller.open).to.have.been.called;
    });

    it("ignores other keys", () => {
      const event = {
        "key": "a",
        "preventDefault": sinon.fake()
      };

      controller.openOnKey(event);

      expect(event.preventDefault).not.to.have.been.called;
      expect(controller.open).not.to.have.been.called;
    });
  });

  describe("#back", () => {
    it("hides the picker", async () => {
      await controller.open();

      controller.back();

      expect(picker.classList.contains("hidden")).to.be.true;
    });

    it("animates the picker closed when motion is enabled", async () => {
      window.matchMedia.returns({ "matches": false });

      await controller.open();

      controller.back();

      expect(picker.classList.contains("closing")).to.be.true;
      expect(picker.classList.contains("hidden")).to.be.false;

      picker.dispatchEvent(new window.Event("transitionend"));

      expect(picker.classList.contains("closing")).to.be.false;
      expect(picker.classList.contains("hidden")).to.be.true;
    });
  });

  describe("#filter", () => {
    beforeEach(async () => {
      await controller.open();
    });

    it("filters the list by case-insensitive label match", async () => {
      search.value = "alp";

      await controller.filter();

      const items = list.querySelectorAll("li");

      expect(items).to.have.lengthOf(1);
      expect(items[0].textContent).to.eq("Alpha");
    });

    it("shows all items when the search is empty", async () => {
      search.value = "";

      await controller.filter();

      const items = list.querySelectorAll("li");

      expect(items).to.have.lengthOf(2);
    });

    it("trims whitespace from the query", async () => {
      search.value = "  alp  ";

      await controller.filter();

      const items = list.querySelectorAll("li");

      expect(items).to.have.lengthOf(1);
      expect(items[0].textContent).to.eq("Alpha");
    });
  });

  describe("#select", () => {
    beforeEach(async () => {
      await controller.open();
    });

    it("updates the hidden field, display, and colors", () => {
      controller.select({
        "currentTarget": {
          "dataset": { "label": "Alpha",
            "value": "1" }
        }
      });

      expect(hiddenField.value).to.eq("1");
      expect(display.textContent).to.eq("Alpha");
      expect(display.classList.contains("text-gray-400")).to.be.false;
      expect(display.classList.contains("text-gray-800")).to.be.true;
      expect(icon.classList.contains("text-taupe-400")).to.be.false;
      expect(icon.classList.contains("text-indigo-600")).to.be.true;
    });

    it("hides the picker", () => {
      controller.select({
        "currentTarget": {
          "dataset": { "label": "Alpha",
            "value": "1" }
        }
      });

      expect(picker.classList.contains("hidden")).to.be.true;
    });
  });

  describe("#beforeRender hook", () => {
    beforeEach(() => {
      sinon.stub(controller, "beforeRender").callsFake(() => {
        const node = document.createElement("li");
        node.textContent = "Create New";
        return node;
      });
    });

    it("prepends the node inside the first group's ul", async () => {
      await controller.open();

      const items = list.querySelectorAll("li");

      expect(items).to.have.lengthOf(3);
      expect(items[0].textContent).to.eq("Create New");
      expect(items[1].textContent).to.eq("Alpha");
    });

    it("prepends the node in its own ul when there are no items", async () => {
      global.fetch = sinon.fake.resolves({
        "json": () => {
          return Promise.resolve([]);
        },
        "ok": true
      });
      delete controller.cachedItems;

      await controller.open();

      expect(list.children).to.have.lengthOf(1);
      expect(list.children[0].tagName).to.eq("UL");
      expect(list.children[0].children[0].textContent).to.eq("Create New");
    });
  });

  describe("#groupFor hook", () => {
    beforeEach(() => {
      global.fetch = sinon.fake.resolves({
        "json": () => {
          return Promise.resolve([
            { "id": 1,
              "name": "Groceries",
              "parent": "Food" },
            { "id": 2,
              "name": "Dining",
              "parent": "Food" },
            { "id": 3,
              "name": "Gas",
              "parent": "Transport" }
          ]);
        },
        "ok": true
      });

      sinon.stub(controller, "groupFor").callsFake((item) => {
        return item.parent;
      });
    });

    it("renders a header and ul per group", async () => {
      await controller.open();

      const headers = list.querySelectorAll("h3");
      const uls = list.querySelectorAll("ul");

      expect(headers).to.have.lengthOf(2);
      expect(headers[0].textContent).to.eq("Food");
      expect(headers[1].textContent).to.eq("Transport");
      expect(uls).to.have.lengthOf(2);
      expect(uls[0].children).to.have.lengthOf(2);
      expect(uls[1].children).to.have.lengthOf(1);
    });

    it("applies grouped spacing to the list container", async () => {
      await controller.open();

      expect(list.classList.contains("space-y-4")).to.be.true;
    });

    it("re-groups on filter and hides empty groups", async () => {
      await controller.open();

      search.value = "gas";
      await controller.filter();

      const headers = list.querySelectorAll("h3");
      const uls = list.querySelectorAll("ul");

      expect(headers).to.have.lengthOf(1);
      expect(headers[0].textContent).to.eq("Transport");
      expect(uls).to.have.lengthOf(1);
      expect(uls[0].children[0].textContent).to.eq("Gas");
    });
  });
});
