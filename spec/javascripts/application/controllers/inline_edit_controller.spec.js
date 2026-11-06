import InlineEditController from "@app/controllers/inline_edit_controller.js";

describe("InlineEditController", () => {
  let cell, form, frame, input, instance;

  beforeEach(() => {
    input = document.createElement("input");
    input.value = "100.00";
    sinon.spy(input, "focus");
    sinon.spy(input, "select");
    sinon.spy(input, "blur");

    form = document.createElement("form");
    form.appendChild(input);
    form.requestSubmit = sinon.stub();

    frame = document.createElement("turbo-frame");
    frame.appendChild(form);

    cell = document.createElement("td");
    cell.appendChild(frame);
    document.body.appendChild(cell);

    instance = new InlineEditController({ "scope": { "element": cell } });
    instance.inputTarget = input;
  });

  describe("#inputTargetConnected", () => {
    it("focuses the input", () => {
      instance.inputTargetConnected();

      expect(input.focus).to.have.been.called;
    });

    it("selects the input text", () => {
      instance.inputTargetConnected();

      expect(input.select).to.have.been.called;
    });

    it("stores the original value", () => {
      instance.inputTargetConnected();

      expect(instance.originalValue).to.eq("100.00");
    });
  });

  describe("#cancel", () => {
    const escape = () => {
      const event = new window.KeyboardEvent("keydown", { "key": "Escape" });

      sinon.spy(event, "preventDefault");
      sinon.spy(event, "stopPropagation");

      return event;
    };

    it("prevents the default event", () => {
      instance.inputTargetConnected();
      const event = escape();

      instance.cancel(event);

      expect(event.preventDefault).to.have.been.called;
    });

    it("stops the event propagation", () => {
      instance.inputTargetConnected();
      const event = escape();

      instance.cancel(event);

      expect(event.stopPropagation).to.have.been.called;
    });

    it("restores the original value and blurs the input", () => {
      instance.inputTargetConnected();
      input.value = "200.00";

      instance.cancel(escape());

      expect(input.value).to.eq("100.00");
      expect(input.blur).to.have.been.called;
    });

    it("discards the edit rather than submitting it", () => {
      instance.inputTargetConnected();
      input.value = "200.00";

      instance.cancel(escape());
      instance.submit();

      expect(form.requestSubmit).not.to.have.been.called;
      expect(frame.src).to.eq(window.location.href);
    });
  });

  describe("#prefocus", () => {

    /*
     * Return the off-screen inputs the controller appends, which carry a style
     * attribute the edit input does not.
     */
    const temporary = () => {
      return document.body.querySelectorAll("input[style]");
    };

    it("creates a temporary input and focuses it", () => {
      instance.prefocus();

      expect(temporary().length).to.eq(1);
      expect(document.activeElement).to.eq(temporary()[0]);
    });

    it("removes the temporary input after a timeout", () => {
      const clock = sinon.useFakeTimers();

      instance.prefocus();
      expect(temporary().length).to.eq(1);

      clock.tick(1000);
      expect(temporary().length).to.eq(0);

      clock.restore();
    });
  });

  describe("#submit", () => {
    it("submits the form when the value has changed", () => {
      instance.inputTargetConnected();
      input.value = "200.00";

      instance.submit();

      expect(form.requestSubmit).to.have.been.called;
    });

    it("restores the frame when the value has not changed", () => {
      instance.inputTargetConnected();

      instance.submit();

      expect(form.requestSubmit).not.to.have.been.called;
      expect(frame.src).to.eq(window.location.href);
    });

    it("restores the frame when the value is blank", () => {
      instance.inputTargetConnected();
      input.value = "";

      instance.submit();

      expect(form.requestSubmit).not.to.have.been.called;
      expect(frame.src).to.eq(window.location.href);
    });
  });

  describe("#submitOnEnter", () => {
    it("prevents the default event and blurs the input", () => {
      instance.inputTargetConnected();
      const event = new window.KeyboardEvent("keydown", { "key": "Enter" });
      sinon.spy(event, "preventDefault");

      instance.submitOnEnter(event);

      expect(event.preventDefault).to.have.been.called;
      expect(input.blur).to.have.been.called;
    });
  });
});
