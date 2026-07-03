import DialogCloser from "@app/shared/dialog_closer.js";

describe("DialogCloser", () => {
  let child,
      closer,
      element,
      onClosed,
      scheduledTimeouts,
      startClose;

  beforeEach(() => {
    scheduledTimeouts = [];

    sinon.stub(window, "setTimeout").callsFake((callback) => {
      scheduledTimeouts.push(callback);

      return scheduledTimeouts.length;
    });
    sinon.stub(window, "clearTimeout");

    element = document.createElement("div");
    child   = document.createElement("span");
    element.appendChild(child);

    onClosed   = sinon.fake();
    startClose = sinon.fake();
    closer     = new DialogCloser();
  });

  afterEach(() => {
    sinon.restore();
  });

  describe("#close", () => {
    it("runs startClose to trigger the slide-out", () => {
      closer.close(element, startClose, onClosed);

      expect(startClose).to.have.been.calledOnce;
    });

    it("runs onClosed once when the element's own transition ends", () => {
      closer.close(element, startClose, onClosed);

      element.dispatchEvent(new window.Event("transitionend"));

      expect(onClosed).to.have.been.calledOnce;
    });

    it("ignores transition events bubbling up from descendants", () => {
      closer.close(element, startClose, onClosed);

      child.dispatchEvent(new window.Event("transitionend", { "bubbles": true }));

      expect(onClosed).not.to.have.been.called;
    });

    it("runs onClosed when the slide-out transition is cancelled", () => {
      closer.close(element, startClose, onClosed);

      element.dispatchEvent(new window.Event("transitioncancel"));

      expect(onClosed).to.have.been.calledOnce;
    });

    it("runs onClosed when no transition event arrives", () => {
      closer.close(element, startClose, onClosed);

      scheduledTimeouts.forEach((callback) => {
        callback();
      });

      expect(onClosed).to.have.been.calledOnce;
    });

    it("runs onClosed only once when a transition event follows a cancel", () => {
      closer.close(element, startClose, onClosed);

      element.dispatchEvent(new window.Event("transitioncancel"));
      element.dispatchEvent(new window.Event("transitionend"));

      expect(onClosed).to.have.been.calledOnce;
    });

    it("ignores a second close while one is already running", () => {
      closer.close(element, startClose, onClosed);
      closer.close(element, startClose, onClosed);

      expect(startClose).to.have.been.calledOnce;
    });

    it("allows a new close after the previous one finishes", () => {
      closer.close(element, startClose, onClosed);
      element.dispatchEvent(new window.Event("transitionend"));

      closer.close(element, startClose, onClosed);

      expect(startClose).to.have.been.calledTwice;
    });
  });

  describe("#cancel", () => {
    it("cancels a pending close without running onClosed", () => {
      closer.close(element, startClose, onClosed);
      element.classList.add("closing");

      closer.cancel(() => {
        return element.classList.remove("closing");
      });
      element.dispatchEvent(new window.Event("transitionend"));

      expect(onClosed).not.to.have.been.called;
      expect(element.classList.contains("closing")).to.be.false;
      expect(window.clearTimeout).to.have.been.called;
    });

    it("cancels without a revert callback", () => {
      closer.close(element, startClose, onClosed);

      closer.cancel();
      element.dispatchEvent(new window.Event("transitionend"));

      expect(onClosed).not.to.have.been.called;
      expect(window.clearTimeout).to.have.been.called;
    });

    it("does nothing when no close is in flight", () => {
      const revert = sinon.fake();

      closer.cancel(revert);

      expect(revert).not.to.have.been.called;
      expect(window.clearTimeout).not.to.have.been.called;
    });

    it("allows a new close after cancelling", () => {
      closer.close(element, startClose, onClosed);
      closer.cancel();

      closer.close(element, startClose, onClosed);

      expect(startClose).to.have.been.calledTwice;
    });
  });
});
