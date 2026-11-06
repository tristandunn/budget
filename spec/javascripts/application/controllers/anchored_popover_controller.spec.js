import AnchoredPopoverController from "@app/controllers/anchored_popover_controller.js";

describe("AnchoredPopoverController", () => {
  let element, instance, menu, trigger;

  const anchor = { "bottom": 120,
    "top": 100 };
  const lowAnchor = { "bottom": 620,
    "top": 600 };

  const fits = { "bottom": 300 };
  const overflowsBottom = { "bottom": 900 };

  const layOut = (menuRect, anchorRect = anchor) => {
    sinon.stub(element, "getBoundingClientRect").returns(anchorRect);
    sinon.stub(menu, "getBoundingClientRect").returns(menuRect);
  };

  const pressKey = (key) => {
    document.dispatchEvent(new window.KeyboardEvent("keydown", { key }));
  };

  beforeEach(() => {
    menu = document.createElement("div");
    trigger = document.createElement("a");

    menu.classList.add("hidden");

    element = document.createElement("div");
    element.append(trigger, menu);
    document.body.appendChild(element);

    instance = new AnchoredPopoverController({ "scope": { element } });
    instance.hasTriggerTarget = true;
    instance.menuTarget = menu;
    instance.triggerTarget = trigger;
    instance.connect();
  });

  afterEach(() => {
    instance.disconnect();
    element.remove();
  });

  describe("#activate", () => {
    let event;

    beforeEach(() => {
      event = new window.Event("click", { "cancelable": true });
    });

    it("leaves the navigation alone when the menu is closed", () => {
      instance.activate(event);

      expect(event.defaultPrevented).to.eq(false);
    });

    it("cancels the navigation when the menu is open", () => {
      instance.open();
      instance.activate(event);

      expect(event.defaultPrevented).to.eq(true);
    });

    it("closes the menu when it is open", () => {
      instance.open();
      instance.activate(event);

      expect(menu.classList.contains("hidden")).to.eq(true);
    });
  });

  describe("#close", () => {
    beforeEach(() => {
      instance.open();
      instance.close();
    });

    it("marks the trigger as collapsed", () => {
      expect(trigger.getAttribute("aria-expanded")).to.eq("false");
    });

    it("stops listening for Escape", () => {
      menu.classList.remove("hidden");

      pressKey("Escape");

      expect(menu.classList.contains("hidden")).to.eq(false);
    });
  });

  describe("#disconnect", () => {
    it("stops listening for Escape", () => {
      instance.open();
      instance.disconnect();
      menu.classList.remove("hidden");

      pressKey("Escape");

      expect(menu.classList.contains("hidden")).to.eq(false);
    });
  });

  describe("#dismiss", () => {
    beforeEach(() => {
      instance.open();
    });

    it("closes the menu on a click outside it", () => {
      document.dispatchEvent(new window.Event("click"));

      expect(menu.classList.contains("hidden")).to.eq(true);
    });

    it("keeps the menu open on a click inside it", () => {
      menu.dispatchEvent(new window.Event("click", { "bubbles": true }));

      expect(menu.classList.contains("hidden")).to.eq(false);
    });
  });

  describe("#open", () => {
    it("marks the trigger as expanded", () => {
      instance.open();

      expect(trigger.getAttribute("aria-expanded")).to.eq("true");
    });

    it("closes the menu on Escape", () => {
      instance.open();
      pressKey("Escape");

      expect(menu.classList.contains("hidden")).to.eq(true);
    });

    it("keeps the menu open on other keys", () => {
      instance.open();
      pressKey("a");

      expect(menu.classList.contains("hidden")).to.eq(false);
    });

    context("when the menu fits below the anchor", () => {
      it("opens below", () => {
        layOut(fits);
        instance.open();

        expect(menu.dataset.placement).to.eq("below");
      });
    });

    context("when the menu overflows the bottom with more room above", () => {
      it("opens above", () => {
        layOut(overflowsBottom, lowAnchor);
        instance.open();

        expect(menu.dataset.placement).to.eq("above");
      });
    });

    context("when the menu overflows the bottom with more room below", () => {
      it("opens below", () => {
        layOut(overflowsBottom);
        instance.open();

        expect(menu.dataset.placement).to.eq("below");
      });
    });

    context("without a trigger", () => {
      it("leaves the trigger alone", () => {
        instance.hasTriggerTarget = false;
        instance.open();

        expect(trigger.hasAttribute("aria-expanded")).to.eq(false);
      });
    });
  });

  describe("#show", () => {
    beforeEach(() => {
      sinon.spy(instance, "open");
    });

    it("opens the menu when hidden", () => {
      instance.show();

      expect(instance.open.calledOnce).to.eq(true);
    });

    it("does not reopen the menu when visible", () => {
      menu.classList.remove("hidden");

      instance.show();

      expect(instance.open.called).to.eq(false);
    });
  });
});
