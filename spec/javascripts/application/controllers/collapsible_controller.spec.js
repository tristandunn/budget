import CollapsibleController from "@app/controllers/collapsible_controller.js";

describe("CollapsibleController", () => {
  let element, instance;

  beforeEach(() => {
    element = document.createElement("tr");

    instance = new CollapsibleController({ "scope": { element } });
    instance.idValue = "category-1";
  });

  afterEach(() => {
    localStorage.clear();
  });

  describe("#connect", () => {
    it("collapses the section if it was previously collapsed", () => {
      localStorage.setItem("budget:collapsed-sections", "[\"category-1\"]");

      instance.connect();

      expect(element.classList.contains("collapsed")).to.eq(true);
    });

    it("does not collapse the section if it was not previously collapsed", () => {
      instance.connect();

      expect(element.classList.contains("collapsed")).to.eq(false);
    });

    it("removes the preload style element", () => {
      const style = document.createElement("style");
      style.id = "collapsible-preload";
      document.head.appendChild(style);

      instance.connect();

      expect(document.getElementById("collapsible-preload")).to.eq(null);
    });
  });

  describe("#toggle", () => {
    it("collapses the section when expanded", () => {
      instance.toggle();

      expect(element.classList.contains("collapsed")).to.eq(true);
    });

    it("expands the section when collapsed", () => {
      element.classList.add("collapsed");

      instance.toggle();

      expect(element.classList.contains("collapsed")).to.eq(false);
    });

    it("persists collapsed state to localStorage", () => {
      instance.toggle();

      expect(JSON.parse(localStorage.getItem("budget:collapsed-sections"))).to.deep.eq(["category-1"]);
    });

    it("removes section from localStorage when expanded", () => {
      localStorage.setItem("budget:collapsed-sections", "[\"category-1\"]");
      element.classList.add("collapsed");

      instance.toggle();

      expect(JSON.parse(localStorage.getItem("budget:collapsed-sections"))).to.deep.eq([]);
    });
  });
});
