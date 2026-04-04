import PopoverController from "@app/controllers/popover_controller.js";

describe("PopoverController", () => {
  let element, instance, menu;

  beforeEach(() => {
    menu = document.createElement("div");
    menu.classList.add("hidden");

    element = document.createElement("div");
    element.appendChild(menu);

    instance = new PopoverController({ "scope": { element } });
    instance.menuTarget = menu;
    instance.connect();
  });

  afterEach(() => {
    instance.disconnect();
  });

  describe("#disconnect", () => {
    it("removes the click outside listener", () => {
      instance.toggle(new window.Event("click"));

      sinon.spy(document, "removeEventListener");

      instance.disconnect();

      expect(document.removeEventListener.calledOnce).to.eq(true);
    });
  });

  describe("#toggle", () => {
    let event;

    beforeEach(() => {
      event = new window.Event("click");
    });

    it("closes the menu when visible", () => {
      menu.classList.remove("hidden");

      instance.toggle(event);

      expect(menu.classList.contains("hidden")).to.eq(true);
    });

    it("opens the menu when hidden", () => {
      sinon.spy(event, "stopPropagation");

      instance.toggle(event);

      expect(menu.classList.contains("hidden")).to.eq(false);
      expect(event.stopPropagation.calledOnce).to.eq(true);
    });

    context("when the menu is open", () => {
      it("closes the menu when clicking outside", () => {
        instance.toggle(event);

        expect(menu.classList.contains("hidden")).to.eq(false);

        document.dispatchEvent(new window.Event("click"));

        expect(menu.classList.contains("hidden")).to.eq(true);
      });
    });
  });
});
