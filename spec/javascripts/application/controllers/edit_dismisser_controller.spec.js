import EditDismisserController from "@app/controllers/edit_dismisser_controller.js";

describe("EditDismisserController", () => {
  let cancel, element, instance;

  const escape = () => {
    const event = new window.KeyboardEvent("keydown", { "key": "Escape" });

    sinon.spy(event, "preventDefault");
    sinon.spy(event, "stopPropagation");

    return event;
  };

  beforeEach(() => {
    cancel = document.createElement("a");
    sinon.spy(cancel, "click");

    element = document.createElement("div");
    element.appendChild(cancel);
    document.body.appendChild(element);

    instance = new EditDismisserController({ "scope": { element } });
    instance.cancelTarget = cancel;
  });

  afterEach(() => {
    document.body.removeChild(element);
  });

  describe("#cancel", () => {
    it("prevents the default event", () => {
      const event = escape();

      instance.cancel(event);

      expect(event.preventDefault).to.have.been.called;
    });

    it("stops the event propagation", () => {
      const event = escape();

      instance.cancel(event);

      expect(event.stopPropagation).to.have.been.called;
    });

    it("follows the cancel link", () => {
      instance.cancel(escape());

      expect(cancel.click).to.have.been.called;
    });
  });
});
