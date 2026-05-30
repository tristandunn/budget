import CategoryPickerController from "@app/controllers/category_picker_controller.js";
import PickerController from "@app/controllers/picker_controller.js";

describe("CategoryPickerController", () => {
  let alpha, beta, gamma, controller, element, groups;

  const buildItem = (label, value) => {
    const item = document.createElement("li");
    item.dataset.categoryPickerTarget = "item";
    item.dataset.label = label;
    item.dataset.value = value;
    item.textContent = label;
    return item;
  };

  const buildGroup = (name, items) => {
    const section = document.createElement("section");
    section.dataset.categoryPickerTarget = "group";

    const heading = document.createElement("h3");
    heading.textContent = name;

    const list = document.createElement("ul");
    items.forEach((item) => {
      return list.appendChild(item);
    });

    section.appendChild(heading);
    section.appendChild(list);
    return section;
  };

  const suggestedSection = () => {
    return groups.querySelector("[data-suggested-group]");
  };

  const suggestedLabels = () => {
    return Array.from(
      suggestedSection().querySelectorAll("[data-category-picker-target='item']"),
      (item) => {
        return item.dataset.label;
      }
    );
  };

  beforeEach(() => {
    element = document.createElement("div");

    alpha = buildItem("Alpha", "1");
    beta  = buildItem("Beta", "2");
    gamma = buildItem("Gamma", "3");

    groups = document.createElement("div");
    groups.dataset.categoryPickerTarget = "groups";
    groups.dataset.suggestedLabel = "Suggested";
    groups.appendChild(buildGroup("Food", [alpha, beta]));
    groups.appendChild(buildGroup("Bills", [gamma]));

    element.appendChild(groups);

    controller = new CategoryPickerController({
      "scope": {
        "element": element,
        "identifier": "category-picker"
      }
    });
    controller.groupsTarget = groups;
  });

  it("subclasses PickerController", () => {
    expect(controller).to.be.instanceOf(PickerController);
  });

  describe("#applySuggestions", () => {
    it("prepends a suggested group with clones of the matching items in order", () => {
      controller.applySuggestions(["3", "1"]);

      const section = suggestedSection();

      expect(groups.firstElementChild).to.eq(section);
      expect(section.querySelector("h3").textContent).to.eq("Suggested");
      expect(suggestedLabels()).to.deep.eq(["Gamma", "Alpha"]);
    });

    it("clones items rather than moving them out of their groups", () => {
      controller.applySuggestions(["1"]);

      expect(groups.querySelectorAll("[data-value='1']")).to.have.lengthOf(2);
    });

    it("skips IDs that do not match a category item", () => {
      controller.applySuggestions(["1", "999"]);

      expect(suggestedLabels()).to.deep.eq(["Alpha"]);
    });

    it("does not add a group when no IDs match", () => {
      controller.applySuggestions(["999"]);

      expect(suggestedSection()).to.be.null;
    });

    it("does not add a group when the ID list is empty", () => {
      controller.applySuggestions([]);

      expect(suggestedSection()).to.be.null;
    });

    it("replaces an existing suggested group rather than stacking", () => {
      controller.applySuggestions(["1", "2"]);
      controller.applySuggestions(["3"]);

      expect(groups.querySelectorAll("[data-suggested-group]")).to.have.lengthOf(1);
      expect(suggestedLabels()).to.deep.eq(["Gamma"]);
    });

    it("clears the suggested group when a later call has no matches", () => {
      controller.applySuggestions(["1"]);
      controller.applySuggestions([]);

      expect(suggestedSection()).to.be.null;
      expect(groups.querySelectorAll("[data-value='1']")).to.have.lengthOf(1);
    });
  });
});
