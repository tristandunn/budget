import TransferFormController from "@app/controllers/transfer_form_controller.js";

describe("TransferFormController", () => {
  let amount, controller, element, fromAccountPickerOutlet, toAccountPickerOutlet;

  beforeEach(() => {
    element = document.createElement("form");

    fromAccountPickerOutlet = { "validate": sinon.fake.returns(true) };
    toAccountPickerOutlet   = { "validate": sinon.fake.returns(true) };

    amount = document.createElement("input");
    amount.type  = "number";
    amount.value = "10";
    amount.classList.add("text-black");

    controller = new TransferFormController({
      "scope": {
        "element": element,
        "identifier": "transfer-form"
      }
    });
    controller.fromAccountPickerOutlet = fromAccountPickerOutlet;
    controller.toAccountPickerOutlet   = toAccountPickerOutlet;
    controller.amountTarget            = amount;
  });

  describe("#validate", () => {
    it("validates each account picker outlet", () => {
      controller.validate({ "preventDefault": sinon.fake() });

      expect(fromAccountPickerOutlet.validate).to.have.been.called;
      expect(toAccountPickerOutlet.validate).to.have.been.called;
    });

    it("does not prevent the submit when every field is valid", () => {
      const event = { "preventDefault": sinon.fake() };

      controller.validate(event);

      expect(event.preventDefault).not.to.have.been.called;
    });

    it("prevents the submit when the from-account picker is empty", () => {
      fromAccountPickerOutlet.validate = sinon.fake.returns(false);

      const event = { "preventDefault": sinon.fake() };

      controller.validate(event);

      expect(event.preventDefault).to.have.been.called;
    });

    it("prevents the submit when the to-account picker is empty", () => {
      toAccountPickerOutlet.validate = sinon.fake.returns(false);

      const event = { "preventDefault": sinon.fake() };

      controller.validate(event);

      expect(event.preventDefault).to.have.been.called;
    });

    it("prevents the submit when the amount is blank", () => {
      amount.value = "";

      const event = { "preventDefault": sinon.fake() };

      controller.validate(event);

      expect(event.preventDefault).to.have.been.called;
      expect(amount.classList.contains("text-red-700")).to.be.true;
      expect(amount.classList.contains("text-black")).to.be.false;
    });

    it("prevents the submit when the amount is zero", () => {
      amount.value = "0.00";

      const event = { "preventDefault": sinon.fake() };

      controller.validate(event);

      expect(event.preventDefault).to.have.been.called;
      expect(amount.classList.contains("text-red-700")).to.be.true;
    });

    it("does not change the amount color when the amount is valid", () => {
      amount.value = "10";

      controller.validate({ "preventDefault": sinon.fake() });

      expect(amount.classList.contains("text-red-700")).to.be.false;
      expect(amount.classList.contains("text-black")).to.be.true;
    });

    it("validates every field even when an earlier field is invalid", () => {
      fromAccountPickerOutlet.validate = sinon.fake.returns(false);
      toAccountPickerOutlet.validate   = sinon.fake.returns(false);
      amount.value                     = "0";

      controller.validate({ "preventDefault": sinon.fake() });

      expect(fromAccountPickerOutlet.validate).to.have.been.called;
      expect(toAccountPickerOutlet.validate).to.have.been.called;
      expect(amount.classList.contains("text-red-700")).to.be.true;
    });
  });
});
