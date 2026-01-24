import CategoryController from "@app/controllers/category_controller.js";

describe("CategoryController", () => {
  let arrow, element, instance, subcategories;

  beforeEach(() => {
    arrow = document.createElement("div");
    arrow.classList.add("rotate-45", "-inset-y-1");

    subcategories = document.createElement("tbody");
    subcategories.setAttribute("data-category-subcategories", "1");
    document.body.appendChild(subcategories);

    element = document.createElement("tr");
    element.appendChild(arrow);

    instance = new CategoryController({ "scope": { element } });
    instance.arrowTarget = arrow;
    instance.subcategoriesIdValue = 1;
  });

  afterEach(() => {
    document.body.removeChild(subcategories);
    localStorage.clear();
  });

  describe("#subcategories", () => {
    it("finds the subcategories element", () => {
      expect(instance.subcategories).to.eq(subcategories);
    });
  });

  describe("#connect", () => {
    it("collapses the category if it was previously collapsed", () => {
      localStorage.setItem("budget:collapsed-categories", "[1]");

      instance.connect();

      expect(subcategories.classList.contains("hidden")).to.eq(true);
      expect(arrow.classList.contains("-rotate-45")).to.eq(true);
    });

    it("does not collapse the category if it was not previously collapsed", () => {
      instance.connect();

      expect(subcategories.classList.contains("hidden")).to.eq(false);
    });
  });

  describe("#toggle", () => {
    it("hides the subcategories when expanded", () => {
      instance.toggle();

      expect(subcategories.classList.contains("hidden")).to.eq(true);
    });

    it("shows the subcategories when collapsed", () => {
      subcategories.classList.add("hidden");

      instance.toggle();

      expect(subcategories.classList.contains("hidden")).to.eq(false);
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

      expect(JSON.parse(localStorage.getItem("budget:collapsed-categories"))).to.deep.eq([1]);
    });

    it("removes category from localStorage when expanded", () => {
      localStorage.setItem("budget:collapsed-categories", "[1]");
      subcategories.classList.add("hidden");

      instance.toggle();

      expect(JSON.parse(localStorage.getItem("budget:collapsed-categories"))).to.deep.eq([]);
    });
  });
});
