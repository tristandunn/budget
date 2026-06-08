import PickerController from "@app/controllers/picker_controller.js";

describe("PickerController", () => {
  let controller, display, element, hiddenField, icon, picker, search;
  let alpha, beta, gamma, groupOne, groupTwo;

  const buildItem = (label, value) => {
    const item = document.createElement("li");
    item.dataset.pickerTarget = "item";
    item.dataset.label = label;
    item.dataset.value = value;
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

    alpha = buildItem("Alpha", "1");
    beta  = buildItem("Beta", "2");
    gamma = buildItem("Gamma", "3");

    groupOne = document.createElement("section");
    groupOne.dataset.pickerTarget = "group";
    const listOne = document.createElement("ul");
    listOne.appendChild(alpha);
    listOne.appendChild(beta);
    groupOne.appendChild(listOne);

    groupTwo = document.createElement("section");
    groupTwo.dataset.pickerTarget = "group";
    const listTwo = document.createElement("ul");
    listTwo.appendChild(gamma);
    groupTwo.appendChild(listTwo);

    element.appendChild(groupOne);
    element.appendChild(groupTwo);

    controller = new PickerController({
      "scope": {
        "element": element,
        "identifier": "picker"
      }
    });
    controller.pickerTarget      = picker;
    controller.searchTarget      = search;
    controller.hasSearchTarget   = true;
    controller.hiddenFieldTarget = hiddenField;
    controller.displayTarget     = display;
    controller.iconTarget        = icon;
    controller.itemTargets       = [alpha, beta, gamma];
    controller.groupTargets      = [groupOne, groupTwo];

    sinon.stub(window, "matchMedia").returns({ "matches": true });
  });

  describe("#open", () => {
    it("shows the picker", () => {
      controller.open();

      expect(picker.classList.contains("hidden")).to.be.false;
      expect(picker.classList.contains("open")).to.be.true;
    });

    it("clears and focuses the search input", () => {
      search.value = "old query";
      document.body.appendChild(search);

      controller.open();

      expect(search.value).to.eq("");
      expect(document.activeElement).to.eq(search);

      document.body.removeChild(search);
    });

    it("forces a reflow when motion is enabled", () => {
      window.matchMedia.returns({ "matches": false });

      controller.open();

      expect(picker.classList.contains("open")).to.be.true;
    });

    it("reveals items that were hidden by a previous search", () => {
      alpha.classList.add("hidden");
      beta.classList.add("hidden");
      groupOne.classList.add("hidden");

      controller.open();

      expect(alpha.classList.contains("hidden")).to.be.false;
      expect(beta.classList.contains("hidden")).to.be.false;
      expect(groupOne.classList.contains("hidden")).to.be.false;
    });

    it("does not touch the search input when no search target is present", () => {
      controller.hasSearchTarget = false;
      search.value = "old query";
      document.body.appendChild(search);

      controller.open();

      expect(search.value).to.eq("old query");
      expect(document.activeElement).not.to.eq(search);

      document.body.removeChild(search);
    });
  });

  describe("#back", () => {
    it("hides the picker", () => {
      controller.open();

      controller.back();

      expect(picker.classList.contains("hidden")).to.be.true;
    });

    it("animates the picker closed when motion is enabled", () => {
      window.matchMedia.returns({ "matches": false });

      controller.open();

      controller.back();

      expect(picker.classList.contains("closing")).to.be.true;
      expect(picker.classList.contains("hidden")).to.be.false;

      picker.dispatchEvent(new window.Event("transitionend"));

      expect(picker.classList.contains("closing")).to.be.false;
      expect(picker.classList.contains("hidden")).to.be.true;
    });
  });

  describe("#filter", () => {
    it("hides items whose label does not include the query", () => {
      search.value = "alp";

      controller.filter();

      expect(alpha.classList.contains("hidden")).to.be.false;
      expect(beta.classList.contains("hidden")).to.be.true;
      expect(gamma.classList.contains("hidden")).to.be.true;
    });

    it("matches case-insensitively", () => {
      search.value = "ALPHA";

      controller.filter();

      expect(alpha.classList.contains("hidden")).to.be.false;
    });

    it("shows all items when the query is empty", () => {
      alpha.classList.add("hidden");

      search.value = "";

      controller.filter();

      expect(alpha.classList.contains("hidden")).to.be.false;
      expect(beta.classList.contains("hidden")).to.be.false;
    });

    it("trims whitespace from the query", () => {
      search.value = "  alp  ";

      controller.filter();

      expect(alpha.classList.contains("hidden")).to.be.false;
      expect(beta.classList.contains("hidden")).to.be.true;
    });

    it("hides groups with no visible items", () => {
      search.value = "alp";

      controller.filter();

      expect(groupOne.classList.contains("hidden")).to.be.false;
      expect(groupTwo.classList.contains("hidden")).to.be.true;
    });

    it("reveals groups when the query is cleared", () => {
      search.value = "gamma";

      controller.filter();

      expect(groupOne.classList.contains("hidden")).to.be.true;

      search.value = "";

      controller.filter();

      expect(groupOne.classList.contains("hidden")).to.be.false;
      expect(groupTwo.classList.contains("hidden")).to.be.false;
    });

    it("is a no-op when there is no search target", () => {
      controller.hasSearchTarget = false;
      sinon.stub(controller, "afterFilter");
      alpha.classList.add("hidden");

      controller.filter();

      expect(alpha.classList.contains("hidden")).to.be.true;
      expect(controller.afterFilter).not.to.have.been.called;
    });

    it("invokes the afterFilter hook with the trimmed query", () => {
      sinon.stub(controller, "afterFilter");

      search.value = "  alp  ";

      controller.filter();

      expect(controller.afterFilter).to.have.been.calledWith("alp");
    });
  });

  describe("#select", () => {
    beforeEach(() => {
      controller.open();
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
      expect(display.classList.contains("text-taupe-400")).to.be.false;
      expect(display.classList.contains("text-taupe-800")).to.be.true;
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

    it("marks the selected item with aria-selected", () => {
      controller.select({ "currentTarget": alpha });

      expect(alpha.getAttribute("aria-selected")).to.eq("true");
    });

    it("clears aria-selected on the other items", () => {
      beta.setAttribute("aria-selected", "true");
      gamma.setAttribute("aria-selected", "true");

      controller.select({ "currentTarget": alpha });

      expect(beta.getAttribute("aria-selected")).to.eq("false");
      expect(gamma.getAttribute("aria-selected")).to.eq("false");
    });

    it("reverts the display and icon colors when an empty value is selected", () => {
      display.classList.remove("text-taupe-400");
      display.classList.add("text-taupe-800");
      icon.classList.remove("text-taupe-400");
      icon.classList.add("text-indigo-600");

      controller.select({
        "currentTarget": {
          "dataset": {
            "label": "Never",
            "value": ""
          }
        }
      });

      expect(hiddenField.value).to.eq("");
      expect(display.textContent).to.eq("Never");
      expect(display.classList.contains("text-taupe-400")).to.be.true;
      expect(display.classList.contains("text-taupe-800")).to.be.false;
      expect(icon.classList.contains("text-taupe-400")).to.be.true;
      expect(icon.classList.contains("text-indigo-600")).to.be.false;
    });

    it("clears the error color from the icon", () => {
      icon.classList.remove("text-taupe-400");
      icon.classList.add("text-red-700");

      controller.select({
        "currentTarget": {
          "dataset": { "label": "Alpha",
            "value": "1" }
        }
      });

      expect(icon.classList.contains("text-red-700")).to.be.false;
    });
  });

  describe("#selectOnKey", () => {
    beforeEach(() => {
      controller.open();
    });

    it("selects a case-insensitive exact label match when Enter is pressed", () => {
      const event = {
        "key": "Enter",
        "preventDefault": sinon.fake()
      };

      search.value = "alpha";

      controller.selectOnKey(event);

      expect(event.preventDefault).to.have.been.called;
      expect(hiddenField.value).to.eq("1");
      expect(display.textContent).to.eq("Alpha");
      expect(picker.classList.contains("hidden")).to.be.true;
    });

    it("trims whitespace from the query before matching", () => {
      const event = {
        "key": "Enter",
        "preventDefault": sinon.fake()
      };

      search.value = "  Alpha  ";

      controller.selectOnKey(event);

      expect(hiddenField.value).to.eq("1");
      expect(display.textContent).to.eq("Alpha");
    });

    it("does nothing when the search has no exact match", () => {
      const event = {
        "key": "Enter",
        "preventDefault": sinon.fake()
      };

      search.value = "alp";

      controller.selectOnKey(event);

      expect(event.preventDefault).to.have.been.called;
      expect(hiddenField.value).to.eq("");
      expect(picker.classList.contains("hidden")).to.be.false;
    });

    it("does nothing when the search is only whitespace", () => {
      const event = {
        "key": "Enter",
        "preventDefault": sinon.fake()
      };

      search.value = "   ";

      controller.selectOnKey(event);

      expect(event.preventDefault).to.have.been.called;
      expect(hiddenField.value).to.eq("");
      expect(picker.classList.contains("hidden")).to.be.false;
    });

    it("ignores other keys", () => {
      const event = {
        "key": "a",
        "preventDefault": sinon.fake()
      };

      search.value = "Alpha";

      controller.selectOnKey(event);

      expect(event.preventDefault).not.to.have.been.called;
      expect(hiddenField.value).to.eq("");
      expect(picker.classList.contains("hidden")).to.be.false;
    });

    it("ignores Enter pressed during IME composition", () => {
      const event = {
        "isComposing": true,
        "key": "Enter",
        "preventDefault": sinon.fake()
      };

      search.value = "Alpha";

      controller.selectOnKey(event);

      expect(event.preventDefault).not.to.have.been.called;
      expect(hiddenField.value).to.eq("");
      expect(picker.classList.contains("hidden")).to.be.false;
    });
  });

  describe("#afterFilter", () => {
    it("is a no-op by default", () => {
      expect(() => {
        return controller.afterFilter("anything");
      }).not.to.throw();
    });
  });

  describe("#validate", () => {
    it("returns true and clears the error color when the hidden field has a value", () => {
      hiddenField.value = "1";
      icon.classList.add("text-red-700");

      const result = controller.validate();

      expect(result).to.be.true;
      expect(icon.classList.contains("text-red-700")).to.be.false;
    });

    it("returns false and marks the icon with the error color when the hidden field is empty", () => {
      hiddenField.value = "";
      icon.classList.add("text-taupe-400");

      const result = controller.validate();

      expect(result).to.be.false;
      expect(icon.classList.contains("text-red-700")).to.be.true;
      expect(icon.classList.contains("text-taupe-400")).to.be.false;
      expect(icon.classList.contains("text-indigo-600")).to.be.false;
    });

    it("removes the indigo color when marking an empty picker as invalid", () => {
      hiddenField.value = "";
      icon.classList.remove("text-taupe-400");
      icon.classList.add("text-indigo-600");

      controller.validate();

      expect(icon.classList.contains("text-indigo-600")).to.be.false;
      expect(icon.classList.contains("text-red-700")).to.be.true;
    });
  });

  describe("#applyValue", () => {
    it("applies the matching item by value, updating the hidden field and display", () => {
      controller.open();

      controller.applyValue("2");

      expect(hiddenField.value).to.eq("2");
      expect(display.textContent).to.eq("Beta");
      expect(beta.getAttribute("aria-selected")).to.eq("true");
    });

    it("leaves the picker open", () => {
      controller.open();

      controller.applyValue("2");

      expect(picker.classList.contains("hidden")).to.be.false;
      expect(picker.classList.contains("closing")).to.be.false;
    });

    it("does not close the picker on a later open when motion is enabled", () => {
      window.matchMedia.returns({ "matches": false });

      controller.applyValue("2");

      controller.open();
      picker.dispatchEvent(new window.Event("transitionend"));

      expect(picker.classList.contains("hidden")).to.be.false;
      expect(picker.classList.contains("open")).to.be.true;
    });

    it("is a no-op when no item matches", () => {
      controller.open();

      controller.applyValue("999");

      expect(hiddenField.value).to.eq("");
      expect(display.textContent).to.eq("");
    });
  });
});
