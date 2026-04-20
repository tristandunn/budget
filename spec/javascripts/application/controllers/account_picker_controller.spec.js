import AccountPickerController from "@app/controllers/account_picker_controller.js";
import PickerController from "@app/controllers/picker_controller.js";

describe("AccountPickerController", () => {
  let controller;

  beforeEach(() => {
    controller = new AccountPickerController({
      "scope": {
        "element": document.createElement("div"),
        "identifier": "account-picker"
      }
    });
  });

  it("subclasses PickerController", () => {
    expect(controller).to.be.instanceOf(PickerController);
  });

  describe("#groupFor", () => {
    it("returns Credit when the item is a credit account", () => {
      expect(controller.groupFor({ "credit": true })).to.eq("Credit");
    });

    it("returns Cash when the item is not a credit account", () => {
      expect(controller.groupFor({ "credit": false })).to.eq("Cash");
    });
  });
});
