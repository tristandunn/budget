import PayeePickerController from "@app/controllers/payee_picker_controller.js";
import PickerController from "@app/controllers/picker_controller.js";

describe("PayeePickerController", () => {
  let controller, createPayeeTemplate, display, hiddenField, icon, list, picker, search;

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

    createPayeeTemplate = document.createElement("template");
    createPayeeTemplate.innerHTML =
      "<li data-action=\"click->payee-picker#select\"><span data-role=\"label\"></span></li>";

    controller = new PayeePickerController({
      "scope": {
        "element": document.createElement("div"),
        "identifier": "payee-picker"
      }
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

  it("subclasses PickerController", () => {
    expect(controller).to.be.instanceOf(PickerController);
  });

  describe("#beforeRender", () => {
    it("returns null when the query is empty", () => {
      expect(controller.beforeRender(["Whole Foods"], "")).to.be.null;
    });

    it("returns null when the query exactly matches a payee", () => {
      expect(controller.beforeRender(["Whole Foods"], "whole foods")).to.be.null;
    });

    it("returns a cloned create template with the query as label and value", () => {
      const node = controller.beforeRender(["Whole Foods"], "Taco");

      expect(node.dataset.value).to.eq("Taco");
      expect(node.dataset.label).to.eq("Taco");
      expect(node.querySelector("[data-role='label']").textContent).to.eq(
        "Create \"Taco\" Payee"
      );
    });
  });

  describe("#filter", () => {
    beforeEach(async () => {
      await controller.open();
    });

    it("prepends a create option when no exact match exists", async () => {
      search.value = "Taco";

      await controller.filter();

      const items = list.querySelectorAll("li");

      expect(items[0].dataset.value).to.eq("Taco");
      expect(items[0].querySelector("[data-role='label']").textContent).to.eq(
        "Create \"Taco\" Payee"
      );
    });

    it("does not show a create option when an exact match exists", async () => {
      search.value = "whole foods";

      await controller.filter();

      const items = list.querySelectorAll("li");

      expect(items).to.have.lengthOf(1);
      expect(items[0].textContent).to.eq("Whole Foods");
    });

    it("trims whitespace from the query for the create option", async () => {
      search.value = "  Taco  ";

      await controller.filter();

      const items = list.querySelectorAll("li");

      expect(items[0].dataset.value).to.eq("Taco");
    });

    it("does not show a create option when the query is only whitespace", async () => {
      search.value = "   ";

      await controller.filter();

      const items = list.querySelectorAll("li");

      expect(items[0].textContent).to.eq("Whole Foods");
    });
  });

  describe("#select via create option", () => {
    it("sets the hidden field and display to the entered name", async () => {
      await controller.open();
      search.value = "Taco";
      await controller.filter();

      const createItem = list.querySelector("li");

      controller.select({ "currentTarget": createItem });

      expect(hiddenField.value).to.eq("Taco");
      expect(display.textContent).to.eq("Taco");
    });
  });

  describe("#selectOnKey", () => {
    it("does not activate the create option when Enter is pressed", async () => {
      await controller.open();
      search.value = "Taco";
      await controller.filter();

      await controller.selectOnKey({
        "key": "Enter",
        "preventDefault": sinon.fake()
      });

      expect(hiddenField.value).to.eq("");
      expect(picker.classList.contains("hidden")).to.be.false;
    });
  });
});
