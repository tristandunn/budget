import DialogController from "@app/controllers/dialog_controller.js";

describe("DialogController", () => {
  let controller,
      dialog,
      scheduledTimeouts;

  beforeEach(() => {
    scheduledTimeouts = [];

    sinon.stub(window, "setTimeout").callsFake((callback) => {
      scheduledTimeouts.push(callback);

      return scheduledTimeouts.length;
    });
    sinon.stub(window, "clearTimeout");

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

  it("does not call showModal when the dialog is already open", () => {
    Object.defineProperty(dialog, "open", { "configurable": true,
      "value": true });

    controller.open();

    expect(dialog.showModal).not.to.have.been.called;
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

  it("forces a reflow before adding the closing class on close", () => {
    const order = [];

    Object.defineProperty(dialog, "offsetHeight", {
      "configurable": true,
      "get": () => {
        order.push("reflow");

        return 0;
      }
    });

    const originalAdd = dialog.classList.add.bind(dialog.classList);
    sinon.stub(dialog.classList, "add").callsFake((...args) => {
      order.push(`add:${args.join(",")}`);

      return originalAdd(...args);
    });

    controller.close();

    expect(order).to.eql(["reflow", "add:closing"]);
  });

  it("forces a reflow before adding the closing class on dismiss", () => {
    const frame = dialog.querySelector("turbo-frame");
    frame.innerHTML = "";
    frame.src = "/redirected";
    globalThis.Turbo = { "visit": sinon.fake() };

    const order = [];

    Object.defineProperty(dialog, "offsetHeight", {
      "configurable": true,
      "get": () => {
        order.push("reflow");

        return 0;
      }
    });

    const originalAdd = dialog.classList.add.bind(dialog.classList);
    sinon.stub(dialog.classList, "add").callsFake((...args) => {
      order.push(`add:${args.join(",")}`);

      return originalAdd(...args);
    });

    controller.open();

    expect(order).to.eql(["reflow", "add:closing"]);

    delete globalThis.Turbo;
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

  it("closes when the slide-out transition is cancelled", () => {
    controller.close();
    dialog.dispatchEvent(new window.Event("transitioncancel"));

    expect(dialog.close).to.have.been.calledOnce;
  });

  it("ignores transition events bubbling up from descendants", () => {
    controller.close();

    const frame = dialog.querySelector("turbo-frame");
    frame.dispatchEvent(new window.Event("transitionend", { "bubbles": true }));

    expect(dialog.close).not.to.have.been.called;
  });

  it("forces the dialog closed when no transition event arrives", () => {
    controller.close();
    scheduledTimeouts.forEach((callback) => {
      callback();
    });

    expect(dialog.close).to.have.been.calledOnce;
  });

  it("closes only once when a transition event follows a cancel", () => {
    controller.close();
    dialog.dispatchEvent(new window.Event("transitioncancel"));
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
    expect(globalThis.Turbo.visit).to.have.been.calledWith("/redirected", { "action": "replace" });

    delete globalThis.Turbo;
  });

  it("visits the redirect URL only once across multiple transition events", () => {
    const frame = dialog.querySelector("turbo-frame");
    frame.innerHTML = "";
    frame.src = "/redirected";

    globalThis.Turbo = { "visit": sinon.fake() };

    controller.open();

    dialog.dispatchEvent(new window.Event("transitionend"));
    dialog.dispatchEvent(new window.Event("transitionend"));

    expect(globalThis.Turbo.visit).to.have.been.calledOnce;

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
    expect(globalThis.Turbo.visit).to.have.been.calledWith("/redirected", { "action": "replace" });

    delete globalThis.Turbo;
  });
});
