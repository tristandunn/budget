import InlineEditController from "@app/controllers/inline_edit_controller.js";

describe("InlineEditController", () => {
  let form, frame, input, instance;

  beforeEach(() => {
    input = document.createElement("input");
    input.value = "100.00";
    sinon.spy(input, "select");
    sinon.spy(input, "blur");

    form = document.createElement("form");
    form.appendChild(input);
    form.requestSubmit = sinon.stub();

    frame = document.createElement("turbo-frame");
    frame.appendChild(form);
    document.body.appendChild(frame);

    instance = new InlineEditController({ "scope": { "element": form } });
    instance.inputTarget = input;
  });

  afterEach(() => {
    document.body.removeChild(frame);
  });

  describe("#connect", () => {
    it("selects the input text", () => {
      instance.connect();

      expect(input.select).to.have.been.called;
    });

    it("stores the original value", () => {
      instance.connect();

      expect(instance.originalValue).to.eq("100.00");
    });
  });

  describe("#cancel", () => {
    it("resets the value and blurs the input", () => {
      instance.connect();
      input.value = "200.00";

      instance.cancel();

      expect(input.value).to.eq("100.00");
      expect(input.blur).to.have.been.called;
    });
  });

  describe("#submit", () => {
    it("submits the form when the value has changed", () => {
      instance.connect();
      input.value = "200.00";

      instance.submit();

      expect(form.requestSubmit).to.have.been.called;
    });

    it("restores the frame when the value has not changed", () => {
      instance.connect();

      instance.submit();

      expect(form.requestSubmit).not.to.have.been.called;
      expect(frame.src).to.eq(window.location.href);
    });

    it("restores the frame when the value is blank", () => {
      instance.connect();
      input.value = "";

      instance.submit();

      expect(form.requestSubmit).not.to.have.been.called;
      expect(frame.src).to.eq(window.location.href);
    });
  });

  describe("#submitOnEnter", () => {
    it("prevents the default event and blurs the input", () => {
      instance.connect();
      const event = new window.KeyboardEvent("keydown", { "key": "Enter" });
      sinon.spy(event, "preventDefault");

      instance.submitOnEnter(event);

      expect(event.preventDefault).to.have.been.called;
      expect(input.blur).to.have.been.called;
    });
  });
});
