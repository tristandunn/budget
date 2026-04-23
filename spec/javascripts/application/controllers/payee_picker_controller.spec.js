import PayeePickerController from "@app/controllers/payee_picker_controller.js";
import PickerController from "@app/controllers/picker_controller.js";

describe("PayeePickerController", () => {
  let alpha, beta, controller, createPayeeTemplate, display, element;
  let hiddenField, icon, list, picker, search;

  const buildItem = (label) => {
    const item = document.createElement("li");
    item.dataset.payeePickerTarget = "item";
    item.dataset.label = label;
    item.dataset.value = label;
    item.textContent = label;
    return item;
  };

  beforeEach(() => {
    element = document.createElement("div");

    picker = document.createElement("div");
    picker.classList.add("hidden");

    search = document.createElement("input");
    search.type = "search";

    hiddenField = document.createElement("input");
    hiddenField.type = "hidden";

    display = document.createElement("span");
    display.classList.add("text-gray-400");

    icon = document.createElement("svg");
    icon.classList.add("text-taupe-400");

    alpha = buildItem("Alpha");
    beta  = buildItem("Beta");

    list = document.createElement("ul");
    list.appendChild(alpha);
    list.appendChild(beta);

    picker.appendChild(list);
    element.appendChild(picker);

    createPayeeTemplate = document.createElement("template");
    createPayeeTemplate.innerHTML =
      "<li data-action=\"click->payee-picker#select\"><span data-role=\"label\"></span></li>";

    controller = new PayeePickerController({
      "scope": {
        "element": element,
        "identifier": "payee-picker"
      }
    });
    controller.pickerTarget              = picker;
    controller.searchTarget              = search;
    controller.hasSearchTarget           = true;
    controller.hiddenFieldTarget         = hiddenField;
    controller.displayTarget             = display;
    controller.iconTarget                = icon;
    controller.itemTargets               = [alpha, beta];
    controller.groupTargets              = [];
    controller.createPayeeTemplateTarget = createPayeeTemplate;

    sinon.stub(window, "matchMedia").returns({ "matches": true });
  });

  it("subclasses PickerController", () => {
    expect(controller).to.be.instanceOf(PickerController);
  });

  describe("#afterFilter", () => {
    it("does nothing when the query is empty", () => {
      controller.afterFilter("");

      expect(list.querySelector("[data-create-option]")).to.be.null;
    });

    it("does nothing when the query exactly matches a payee", () => {
      controller.afterFilter("alpha");

      expect(list.querySelector("[data-create-option]")).to.be.null;
    });

    it("prepends a create option when no exact match exists", () => {
      controller.afterFilter("Taco");

      const createOption = list.querySelector("[data-create-option]");

      expect(createOption).not.to.be.null;
      expect(list.firstElementChild).to.eq(createOption);
      expect(createOption.dataset.value).to.eq("Taco");
      expect(createOption.dataset.label).to.eq("Taco");
      expect(createOption.querySelector("[data-role='label']").textContent).to.eq(
        "Create \"Taco\" Payee"
      );
    });

    it("replaces the existing create option without stacking", () => {
      controller.afterFilter("Taco");
      controller.afterFilter("Tacos");

      const options = list.querySelectorAll("[data-create-option]");

      expect(options).to.have.lengthOf(1);
      expect(options[0].dataset.value).to.eq("Tacos");
    });

    it("removes the create option when the query becomes empty", () => {
      controller.afterFilter("Taco");
      controller.afterFilter("");

      expect(list.querySelector("[data-create-option]")).to.be.null;
    });

    it("removes the create option when the query exactly matches a payee", () => {
      controller.afterFilter("Taco");
      controller.afterFilter("alpha");

      expect(list.querySelector("[data-create-option]")).to.be.null;
    });
  });

  describe("#filter", () => {
    it("inserts the create option via the afterFilter hook", () => {
      search.value = "Taco";

      controller.filter();

      const createOption = list.querySelector("[data-create-option]");

      expect(createOption).not.to.be.null;
      expect(createOption.dataset.label).to.eq("Taco");
    });
  });

  describe("#select via create option", () => {
    it("sets the hidden field and display to the entered name", () => {
      search.value = "Taco";
      controller.filter();

      const createOption = list.querySelector("[data-create-option]");

      controller.select({ "currentTarget": createOption });

      expect(hiddenField.value).to.eq("Taco");
      expect(display.textContent).to.eq("Taco");
    });
  });

  describe("#selectOnKey", () => {
    it("does not activate the create option when Enter is pressed", () => {
      controller.open();
      search.value = "Taco";
      controller.filter();

      controller.selectOnKey({
        "key": "Enter",
        "preventDefault": sinon.fake()
      });

      expect(hiddenField.value).to.eq("");
      expect(picker.classList.contains("hidden")).to.be.false;
    });
  });
});
