import DialogDismisserController from "@app/controllers/dialog_dismisser_controller.js";

describe("DialogDismisserController", () => {
  let controller,
      element;

  beforeEach(() => {
    element = document.createElement("div");

    controller = new DialogDismisserController({
      "scope": { "element": element }
    });
  });

  afterEach(() => {
    sinon.restore();
  });

  it("dispatches a bubbling dialog:close event on connect", () => {
    const listener = sinon.fake();
    element.addEventListener("dialog:close", listener);

    controller.connect();

    expect(listener).to.have.been.calledOnce;
    expect(listener.firstCall.firstArg.bubbles).to.be.true;
  });
});
