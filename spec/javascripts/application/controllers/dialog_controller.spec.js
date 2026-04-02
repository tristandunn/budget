import DialogController from "@app/controllers/dialog_controller.js";

describe("DialogController", () => {
  let controller,
      dialog;

  beforeEach(() => {
    window.matchMedia = () => {
      return { "matches": false };
    };

    dialog = document.createElement("dialog");
    dialog.showModal = sinon.fake();
    dialog.close = sinon.fake();

    const frame = document.createElement("turbo-frame");
    frame.innerHTML = "<p>Content</p>";
    dialog.appendChild(frame);

    controller = new DialogController({
      "scope": { "element": document.createElement("div") }
    });
    controller.dialogTarget = dialog;
  });

  afterEach(() => {
    sinon.restore();
  });

  it("opens the dialog when open is called", () => {
    controller.open();

    expect(dialog.showModal).to.have.been.calledOnce;
    expect(dialog.classList.contains("open")).to.be.true;
  });

  it("opens without reflow when prefers-reduced-motion is enabled", () => {
    sinon.stub(window, "matchMedia").returns({ "matches": true });

    controller.open();

    expect(dialog.showModal).to.have.been.calledOnce;
    expect(dialog.classList.contains("open")).to.be.true;
  });

  it("adds the closing class when close is called", () => {
    controller.close();

    expect(dialog.classList.contains("closing")).to.be.true;
  });

  it("closes the dialog after the transition ends", () => {
    controller.close();
    dialog.dispatchEvent(new window.Event("transitionend"));

    expect(dialog.close).to.have.been.calledOnce;
    expect(dialog.classList.contains("closing")).to.be.false;
    expect(dialog.classList.contains("open")).to.be.false;
  });

  it("clears the turbo frame content after closing", () => {
    controller.close();
    dialog.dispatchEvent(new window.Event("transitionend"));

    expect(dialog.querySelector("turbo-frame").innerHTML).to.eq("");
  });

  it("ignores a second close call while already closing", () => {
    controller.close();
    controller.close();

    dialog.dispatchEvent(new window.Event("transitionend"));

    expect(dialog.close).to.have.been.calledOnce;
  });

  it("closes immediately when prefers-reduced-motion is enabled", () => {
    sinon.stub(window, "matchMedia").returns({ "matches": true });

    dialog.classList.add("open");
    controller.close();

    expect(dialog.close).to.have.been.calledOnce;
    expect(dialog.classList.contains("closing")).to.be.false;
    expect(dialog.classList.contains("open")).to.be.false;
    expect(dialog.querySelector("turbo-frame").innerHTML).to.eq("");
  });

  it("closes on backdrop click", () => {
    sinon.stub(controller, "close");

    controller.backdropClose({ "target": dialog });

    expect(controller.close).to.have.been.calledOnce;
  });

  it("does not close when clicking inside the dialog", () => {
    sinon.stub(controller, "close");
    const child = document.createElement("div");

    controller.backdropClose({ "target": child });

    expect(controller.close).not.to.have.been.called;
  });

  it("prevents default cancel and closes with animation", () => {
    sinon.stub(controller, "close");
    const event = { "preventDefault": sinon.fake() };

    controller.cancel(event);

    expect(event.preventDefault).to.have.been.calledOnce;
    expect(controller.close).to.have.been.calledOnce;
  });

  it("dismisses and visits the redirect URL after a form submission", () => {
    const frame = dialog.querySelector("turbo-frame");
    frame.innerHTML = "";
    frame.src = "/redirected";

    globalThis.Turbo = { "visit": sinon.fake() };

    controller.open();

    expect(dialog.showModal).not.to.have.been.called;
    expect(dialog.classList.contains("closing")).to.be.true;
    expect(globalThis.Turbo.visit).not.to.have.been.called;

    dialog.dispatchEvent(new window.Event("transitionend"));

    expect(dialog.close).to.have.been.calledOnce;
    expect(globalThis.Turbo.visit).to.have.been.calledWith("/redirected");

    delete globalThis.Turbo;
  });

  it("dismisses without animation when prefers-reduced-motion is enabled", () => {
    const frame = dialog.querySelector("turbo-frame");
    frame.innerHTML = "";
    frame.src = "/redirected";

    globalThis.Turbo = { "visit": sinon.fake() };
    sinon.stub(window, "matchMedia").returns({ "matches": true });

    controller.open();

    expect(dialog.close).to.have.been.calledOnce;
    expect(globalThis.Turbo.visit).to.have.been.calledWith("/redirected");

    delete globalThis.Turbo;
  });
});
