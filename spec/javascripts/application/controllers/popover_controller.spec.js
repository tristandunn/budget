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

  describe("#connect", () => {
    it("closes the menu before the page is cached", () => {
      menu.classList.remove("hidden");

      document.dispatchEvent(new window.Event("turbo:before-cache"));

      expect(menu.classList.contains("hidden")).to.eq(true);
    });
  });

  describe("#disconnect", () => {
    const boundFor = (type) => {
      return document.addEventListener.
        getCalls().
        find((call) => {
          return call.args[0] === type;
        }).args[1];
    };

    beforeEach(() => {
      instance.disconnect();

      sinon.spy(document, "addEventListener");
      sinon.spy(document, "removeEventListener");

      instance.connect();
      instance.toggle(new window.Event("click"));
      instance.disconnect();
    });

    it("unbinds the click listener it bound", () => {
      expect(
        document.removeEventListener.calledWith("click", boundFor("click"))
      ).to.eq(true);
    });

    it("unbinds the before-cache listener it bound", () => {
      expect(
        document.removeEventListener.calledWith(
          "turbo:before-cache",
          boundFor("turbo:before-cache")
        )
      ).to.eq(true);
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
