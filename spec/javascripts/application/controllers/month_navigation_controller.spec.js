import MonthNavigationController from "@app/controllers/month_navigation_controller.js";

describe("MonthNavigationController", () => {
  let element, instance, next, previous;

  beforeEach(() => {
    previous = document.createElement("a");
    next = document.createElement("a");

    sinon.spy(previous, "click");
    sinon.spy(next, "click");

    element = document.createElement("div");
    element.appendChild(previous);
    element.appendChild(next);
    document.body.appendChild(element);

    instance = new MonthNavigationController({ "scope": { element } });
    instance.previousTarget = previous;
    instance.nextTarget = next;
    instance.connect();
  });

  afterEach(() => {
    instance.disconnect();
    element.remove();
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
      instance.disconnect();
    });

    it("unbinds the keydown listener it bound", () => {
      expect(
        document.removeEventListener.calledWith("keydown", boundFor("keydown"))
      ).to.eq(true);
    });
  });

  describe("when the left arrow key is pressed", () => {
    it("clicks the previous month link", () => {
      document.dispatchEvent(new window.KeyboardEvent("keydown", { "key": "ArrowLeft" }));

      expect(previous.click.calledOnce).to.eq(true);
      expect(next.click.called).to.eq(false);
    });

    it("ignores a disabled previous month link", () => {
      previous.setAttribute("aria-disabled", "true");

      document.dispatchEvent(new window.KeyboardEvent("keydown", { "key": "ArrowLeft" }));

      expect(previous.click.called).to.eq(false);
    });
  });

  describe("when the right arrow key is pressed", () => {
    it("clicks the next month link", () => {
      document.dispatchEvent(new window.KeyboardEvent("keydown", { "key": "ArrowRight" }));

      expect(next.click.calledOnce).to.eq(true);
      expect(previous.click.called).to.eq(false);
    });

    it("ignores a disabled next month link", () => {
      next.setAttribute("aria-disabled", "true");

      document.dispatchEvent(new window.KeyboardEvent("keydown", { "key": "ArrowRight" }));

      expect(next.click.called).to.eq(false);
    });
  });

  describe("when another key is pressed", () => {
    it("clicks neither link", () => {
      document.dispatchEvent(new window.KeyboardEvent("keydown", { "key": "ArrowUp" }));

      expect(previous.click.called).to.eq(false);
      expect(next.click.called).to.eq(false);
    });
  });

  describe("when a modifier key is held", () => {
    it("clicks neither link", () => {
      document.dispatchEvent(
        new window.KeyboardEvent("keydown", { "key": "ArrowLeft",
          "metaKey": true })
      );

      expect(previous.click.called).to.eq(false);
      expect(next.click.called).to.eq(false);
    });
  });

  describe("when the event originates from an editable field", () => {
    it("clicks neither link", () => {
      const input = document.createElement("input");
      element.appendChild(input);

      input.dispatchEvent(
        new window.KeyboardEvent("keydown", { "bubbles": true,
          "key": "ArrowLeft" })
      );

      expect(previous.click.called).to.eq(false);
      expect(next.click.called).to.eq(false);
    });
  });

  describe("when a dialog is open", () => {
    it("clicks neither link", () => {
      const dialog = document.createElement("dialog");
      dialog.setAttribute("open", "");
      document.body.appendChild(dialog);

      document.dispatchEvent(new window.KeyboardEvent("keydown", { "key": "ArrowLeft" }));

      expect(previous.click.called).to.eq(false);
      expect(next.click.called).to.eq(false);

      dialog.remove();
    });
  });
});
