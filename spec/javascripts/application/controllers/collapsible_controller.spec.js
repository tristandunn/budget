import CollapsibleController from "@app/controllers/collapsible_controller.js";

describe("CollapsibleController", () => {
  let arrow, content, element, instance;

  beforeEach(() => {
    arrow = document.createElement("div");
    arrow.classList.add("rotate-45", "-inset-y-1");

    content = document.createElement("tbody");
    content.setAttribute("data-collapsible-content", "collapsible-category-1");
    document.body.appendChild(content);

    element = document.createElement("tr");
    element.appendChild(arrow);

    instance = new CollapsibleController({ "scope": { element } });
    instance.arrowTarget = arrow;
    instance.idValue = "category-1";
  });

  afterEach(() => {
    document.body.removeChild(content);
    localStorage.clear();
  });

  describe("#content", () => {
    it("finds the content element", () => {
      expect(instance.content).to.eq(content);
    });
  });

  describe("#connect", () => {
    it("collapses the section if it was previously collapsed", () => {
      localStorage.setItem("budget:collapsed-sections", "[\"category-1\"]");

      instance.connect();

      expect(content.classList.contains("hidden")).to.eq(true);
      expect(arrow.classList.contains("-rotate-45")).to.eq(true);
    });

    it("does not collapse the section if it was not previously collapsed", () => {
      instance.connect();

      expect(content.classList.contains("hidden")).to.eq(false);
    });
  });

  describe("#toggle", () => {
    it("hides the content when expanded", () => {
      instance.toggle();

      expect(content.classList.contains("hidden")).to.eq(true);
    });

    it("shows the content when collapsed", () => {
      content.classList.add("hidden");

      instance.toggle();

      expect(content.classList.contains("hidden")).to.eq(false);
    });

    it("rotates the arrow when toggling", () => {
      instance.toggle();

      expect(arrow.classList.contains("rotate-45")).to.eq(false);
      expect(arrow.classList.contains("-rotate-45")).to.eq(true);
    });

    it("adjusts the arrow position when toggling", () => {
      instance.toggle();

      expect(arrow.classList.contains("-inset-y-1")).to.eq(false);
      expect(arrow.classList.contains("inset-y-0")).to.eq(true);
    });

    it("persists collapsed state to localStorage", () => {
      instance.toggle();

      expect(JSON.parse(localStorage.getItem("budget:collapsed-sections"))).to.deep.eq(["category-1"]);
    });

    it("removes section from localStorage when expanded", () => {
      localStorage.setItem("budget:collapsed-sections", "[\"category-1\"]");
      content.classList.add("hidden");

      instance.toggle();

      expect(JSON.parse(localStorage.getItem("budget:collapsed-sections"))).to.deep.eq([]);
    });
  });
});
