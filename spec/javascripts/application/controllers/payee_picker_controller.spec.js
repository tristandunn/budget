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
    display.classList.add("text-taupe-400");

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

  describe("#select with a defaults URL", () => {
    let accountPickerOutlet, categoryPickerOutlet;

    beforeEach(() => {
      accountPickerOutlet = {
        "applyValue": sinon.fake(),
        "hiddenFieldTarget": { "value": "" }
      };
      categoryPickerOutlet = {
        "applyValue": sinon.fake(),
        "hiddenFieldTarget": { "value": "" }
      };

      alpha.dataset.defaultsUrl          = "/payees/1/defaults";
      controller.hasAccountPickerOutlet  = true;
      controller.accountPickerOutlet     = accountPickerOutlet;
      controller.hasCategoryPickerOutlet = true;
      controller.categoryPickerOutlet    = categoryPickerOutlet;

      globalThis.fetch = sinon.fake();
    });

    it("applies both defaults on their picker outlets", async () => {
      globalThis.fetch = sinon.fake.resolves({
        "json": () => {
          return Promise.resolve({
            "account_id": 9,
            "subcategory_id": 42
          });
        },
        "ok": true
      });

      await controller.select({ "currentTarget": alpha });

      expect(globalThis.fetch).to.have.been.calledWith(
        "/payees/1/defaults",
        { "headers": { "Accept": "application/json" } }
      );
      expect(accountPickerOutlet.applyValue).to.have.been.calledWith(9);
      expect(categoryPickerOutlet.applyValue).to.have.been.calledWith(42);
    });

    it("does nothing when the response is not ok", async () => {
      globalThis.fetch = sinon.fake.resolves({ "ok": false });

      await controller.select({ "currentTarget": alpha });

      expect(accountPickerOutlet.applyValue).not.to.have.been.called;
      expect(categoryPickerOutlet.applyValue).not.to.have.been.called;
    });

    it("does not apply either picker when both IDs in the response are empty", async () => {
      globalThis.fetch = sinon.fake.resolves({
        "json": () => {
          return Promise.resolve({
            "account_id": "",
            "subcategory_id": ""
          });
        },
        "ok": true
      });

      await controller.select({ "currentTarget": alpha });

      expect(accountPickerOutlet.applyValue).not.to.have.been.called;
      expect(categoryPickerOutlet.applyValue).not.to.have.been.called;
    });

    it("does not apply the account when only the subcategory ID is returned", async () => {
      globalThis.fetch = sinon.fake.resolves({
        "json": () => {
          return Promise.resolve({
            "account_id": "",
            "subcategory_id": 42
          });
        },
        "ok": true
      });

      await controller.select({ "currentTarget": alpha });

      expect(accountPickerOutlet.applyValue).not.to.have.been.called;
      expect(categoryPickerOutlet.applyValue).to.have.been.calledWith(42);
    });

    it("does not apply the subcategory when only the account ID is returned", async () => {
      globalThis.fetch = sinon.fake.resolves({
        "json": () => {
          return Promise.resolve({
            "account_id": 9,
            "subcategory_id": ""
          });
        },
        "ok": true
      });

      await controller.select({ "currentTarget": alpha });

      expect(accountPickerOutlet.applyValue).to.have.been.calledWith(9);
      expect(categoryPickerOutlet.applyValue).not.to.have.been.called;
    });

    it("does nothing when the item has no defaults url", async () => {
      delete alpha.dataset.defaultsUrl;

      await controller.select({ "currentTarget": alpha });

      expect(globalThis.fetch).not.to.have.been.called;
      expect(accountPickerOutlet.applyValue).not.to.have.been.called;
      expect(categoryPickerOutlet.applyValue).not.to.have.been.called;
    });

    it("does not fetch when both outlets are missing", async () => {
      controller.hasAccountPickerOutlet  = false;
      controller.hasCategoryPickerOutlet = false;

      await controller.select({ "currentTarget": alpha });

      expect(globalThis.fetch).not.to.have.been.called;
    });

    it("still applies the subcategory when the account picker outlet is missing", async () => {
      controller.hasAccountPickerOutlet = false;

      globalThis.fetch = sinon.fake.resolves({
        "json": () => {
          return Promise.resolve({
            "account_id": 9,
            "subcategory_id": 42
          });
        },
        "ok": true
      });

      await controller.select({ "currentTarget": alpha });

      expect(categoryPickerOutlet.applyValue).to.have.been.calledWith(42);
    });

    it("still applies the account when the category picker outlet is missing", async () => {
      controller.hasCategoryPickerOutlet = false;

      globalThis.fetch = sinon.fake.resolves({
        "json": () => {
          return Promise.resolve({
            "account_id": 9,
            "subcategory_id": 42
          });
        },
        "ok": true
      });

      await controller.select({ "currentTarget": alpha });

      expect(accountPickerOutlet.applyValue).to.have.been.calledWith(9);
    });

    it("does not fetch when both pickers already have values", async () => {
      accountPickerOutlet.hiddenFieldTarget.value  = "3";
      categoryPickerOutlet.hiddenFieldTarget.value = "7";

      await controller.select({ "currentTarget": alpha });

      expect(globalThis.fetch).not.to.have.been.called;
      expect(accountPickerOutlet.applyValue).not.to.have.been.called;
      expect(categoryPickerOutlet.applyValue).not.to.have.been.called;
    });

    it("does not overwrite an account that already has a value", async () => {
      accountPickerOutlet.hiddenFieldTarget.value = "3";

      globalThis.fetch = sinon.fake.resolves({
        "json": () => {
          return Promise.resolve({
            "account_id": 9,
            "subcategory_id": 42
          });
        },
        "ok": true
      });

      await controller.select({ "currentTarget": alpha });

      expect(accountPickerOutlet.applyValue).not.to.have.been.called;
      expect(categoryPickerOutlet.applyValue).to.have.been.calledWith(42);
    });

    it("does not overwrite a subcategory that already has a value", async () => {
      categoryPickerOutlet.hiddenFieldTarget.value = "7";

      globalThis.fetch = sinon.fake.resolves({
        "json": () => {
          return Promise.resolve({
            "account_id": 9,
            "subcategory_id": 42
          });
        },
        "ok": true
      });

      await controller.select({ "currentTarget": alpha });

      expect(accountPickerOutlet.applyValue).to.have.been.calledWith(9);
      expect(categoryPickerOutlet.applyValue).not.to.have.been.called;
    });

    it("does not overwrite an account picked while the fetch is in flight", async () => {
      let resolveFetch;

      globalThis.fetch = sinon.fake.returns(new Promise((resolve) => {
        resolveFetch = resolve;
      }));

      const selecting = controller.select({ "currentTarget": alpha });

      accountPickerOutlet.hiddenFieldTarget.value = "5";

      resolveFetch({
        "json": () => {
          return Promise.resolve({
            "account_id": 9,
            "subcategory_id": 42
          });
        },
        "ok": true
      });

      await selecting;

      expect(accountPickerOutlet.applyValue).not.to.have.been.called;
      expect(categoryPickerOutlet.applyValue).to.have.been.calledWith(42);
    });

    it("does not overwrite a subcategory picked while the fetch is in flight", async () => {
      let resolveFetch;

      globalThis.fetch = sinon.fake.returns(new Promise((resolve) => {
        resolveFetch = resolve;
      }));

      const selecting = controller.select({ "currentTarget": alpha });

      categoryPickerOutlet.hiddenFieldTarget.value = "7";

      resolveFetch({
        "json": () => {
          return Promise.resolve({
            "account_id": 9,
            "subcategory_id": 42
          });
        },
        "ok": true
      });

      await selecting;

      expect(accountPickerOutlet.applyValue).to.have.been.calledWith(9);
      expect(categoryPickerOutlet.applyValue).not.to.have.been.called;
    });

    it("applies the fetched defaults when selecting via Enter on an exact match", async () => {
      globalThis.fetch = sinon.fake.resolves({
        "json": () => {
          return Promise.resolve({
            "account_id": 9,
            "subcategory_id": 42
          });
        },
        "ok": true
      });

      controller.open();
      search.value = "Alpha";

      await controller.selectOnKey({
        "key": "Enter",
        "preventDefault": sinon.fake()
      });

      expect(globalThis.fetch).to.have.been.calledWith(
        "/payees/1/defaults",
        { "headers": { "Accept": "application/json" } }
      );
      expect(accountPickerOutlet.applyValue).to.have.been.calledWith(9);
      expect(categoryPickerOutlet.applyValue).to.have.been.calledWith(42);
    });
  });
});
