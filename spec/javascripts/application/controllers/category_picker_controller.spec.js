import CategoryPickerController from "@app/controllers/category_picker_controller.js";
import PickerController from "@app/controllers/picker_controller.js";

describe("CategoryPickerController", () => {
  let controller;

  beforeEach(() => {
    controller = new CategoryPickerController({
      "scope": {
        "element": document.createElement("div"),
        "identifier": "category-picker"
      }
    });
  });

  it("subclasses PickerController", () => {
    expect(controller).to.be.instanceOf(PickerController);
  });

  describe("#groupFor", () => {
    it("returns the parent_name of the item", () => {
      expect(controller.groupFor({ "parent_name": "Food" })).to.eq("Food");
    });

    it("returns undefined when the item has no parent_name", () => {
      expect(controller.groupFor({})).to.be.undefined;
    });
  });
});
