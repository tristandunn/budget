import ConfirmController from "@app/controllers/confirm_controller.js";

describe("ConfirmController", () => {
  let element, instance, panel;

  beforeEach(() => {
    panel = document.createElement("div");

    element = document.createElement("div");
    element.appendChild(panel);
    document.body.appendChild(element);

    instance = new ConfirmController({ "scope": { element } });
    instance.panelTarget = panel;
    instance.connect();
  });

  afterEach(() => {
    instance.disconnect();
    element.remove();
  });

  describe("#connect", () => {
    it("hides the panel", () => {
      panel.hidden = false;

      instance.connect();

      expect(panel.hidden).to.eq(true);
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
      sinon.spy(document, "addEventListener");
      sinon.spy(document, "removeEventListener");

      instance.prompt();
      instance.disconnect();
    });

    it("unbinds the click listener it bound", () => {
      expect(
        document.removeEventListener.calledWith("click", boundFor("click"))
      ).to.eq(true);
    });

    it("unbinds the keydown listener it bound", () => {
      expect(
        document.removeEventListener.calledWith("keydown", boundFor("keydown"))
      ).to.eq(true);
    });
  });

  describe("#prompt", () => {
    it("reveals the panel", () => {
      instance.prompt();

      expect(panel.hidden).to.eq(false);
    });
  });

  describe("#cancel", () => {
    it("hides the panel", () => {
      instance.prompt();

      instance.cancel();

      expect(panel.hidden).to.eq(true);
    });
  });

  describe("when the panel is open", () => {
    beforeEach(() => {
      instance.prompt();
    });

    it("cancels when clicking outside the controller", () => {
      document.dispatchEvent(new window.Event("click"));

      expect(panel.hidden).to.eq(true);
    });

    it("ignores clicks within the controller", () => {
      panel.dispatchEvent(new window.Event("click", { "bubbles": true }));

      expect(panel.hidden).to.eq(false);
    });

    it("cancels when the escape key is pressed", () => {
      document.dispatchEvent(new window.KeyboardEvent("keydown", { "key": "Escape" }));

      expect(panel.hidden).to.eq(true);
    });

    it("ignores other keys", () => {
      document.dispatchEvent(new window.KeyboardEvent("keydown", { "key": "Enter" }));

      expect(panel.hidden).to.eq(false);
    });
  });

  describe("#stop", () => {
    it("stops the event from propagating", () => {
      const event = new window.Event("click");

      sinon.spy(event, "stopPropagation");

      instance.stop(event);

      expect(event.stopPropagation.calledOnce).to.eq(true);
    });
  });
});
