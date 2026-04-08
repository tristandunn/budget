import PayeePickerController from "@app/controllers/payee_picker_controller.js";

describe("PayeePickerController", () => {
  let controller, createPayeeTemplate, display, hiddenField, icon, list, picker, search;

  beforeEach(() => {
    picker = document.createElement("div");
    picker.classList.add("hidden");

    search = document.createElement("input");
    search.type = "search";

    list = document.createElement("ul");

    hiddenField = document.createElement("input");
    hiddenField.type = "hidden";

    display = document.createElement("span");
    display.classList.add("text-gray-400");

    icon = document.createElement("svg");
    icon.classList.add("text-taupe-400");

    createPayeeTemplate = document.createElement("template");
    createPayeeTemplate.innerHTML =
      "<li data-action=\"click->payee-picker#select\"><span data-role=\"label\"></span></li>";

    controller = new PayeePickerController({
      "scope": { "element": document.createElement("div") }
    });
    controller.createPayeeTemplateTarget = createPayeeTemplate;
    controller.pickerTarget = picker;
    controller.searchTarget = search;
    controller.listTarget = list;
    controller.hiddenFieldTarget = hiddenField;
    controller.displayTarget = display;
    controller.iconTarget = icon;
    controller.urlValue = "/budgets/1/payees";

    global.fetch = sinon.fake.resolves({
      "json": () => {
        return Promise.resolve(["Whole Foods", "Coffee Shop", "Gas Station"]);
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

    it("fetches payees and renders the list", async () => {
      await controller.open();

      expect(list.children).to.have.lengthOf(3);
      expect(list.children[0].textContent).to.eq("Whole Foods");
      expect(list.children[1].textContent).to.eq("Coffee Shop");
      expect(list.children[2].textContent).to.eq("Gas Station");
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

    it("caches payees after the first fetch", async () => {
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

    it("filters the list by case-insensitive substring match", async () => {
      search.value = "coffee";

      await controller.filter();

      expect(list.children).to.have.lengthOf(2);
      expect(list.children[0].textContent).to.eq("Create \"coffee\" Payee");
      expect(list.children[1].textContent).to.eq("Coffee Shop");
    });

    it("shows all payees when the search is empty", async () => {
      search.value = "";

      await controller.filter();

      expect(list.children).to.have.lengthOf(3);
    });

    it("prepends a create option when no exact match exists", async () => {
      search.value = "Taco";

      await controller.filter();

      expect(list.children[0].textContent).to.eq("Create \"Taco\" Payee");
      expect(list.children[0].dataset.value).to.eq("Taco");
    });

    it("does not show a create option when an exact match exists", async () => {
      search.value = "whole foods";

      await controller.filter();

      expect(list.children).to.have.lengthOf(1);
      expect(list.children[0].textContent).to.eq("Whole Foods");
    });

    it("trims whitespace from the query for the create option", async () => {
      search.value = "  Taco  ";

      await controller.filter();

      expect(list.children[0].textContent).to.eq("Create \"Taco\" Payee");
      expect(list.children[0].dataset.value).to.eq("Taco");
    });

    it("does not show a create option when the query is only whitespace", async () => {
      search.value = "   ";

      await controller.filter();

      expect(list.children[0].textContent).to.eq("Whole Foods");
    });
  });

  describe("#select", () => {
    beforeEach(async () => {
      await controller.open();
    });

    it("updates the hidden field, display, and colors", () => {
      controller.select({ "currentTarget": { "dataset": { "value": "Whole Foods" } } });

      expect(hiddenField.value).to.eq("Whole Foods");
      expect(display.textContent).to.eq("Whole Foods");
      expect(display.classList.contains("text-gray-400")).to.be.false;
      expect(display.classList.contains("text-gray-800")).to.be.true;
      expect(icon.classList.contains("text-taupe-400")).to.be.false;
      expect(icon.classList.contains("text-indigo-600")).to.be.true;
    });

    it("hides the picker", () => {
      controller.select({ "currentTarget": { "dataset": { "value": "Whole Foods" } } });

      expect(picker.classList.contains("hidden")).to.be.true;
    });
  });
});
