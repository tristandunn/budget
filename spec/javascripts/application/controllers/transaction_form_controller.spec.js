import TransactionFormController from "@app/controllers/transaction_form_controller.js";

describe("TransactionFormController", () => {
  let accountPickerOutlet, amount, categoryPickerOutlet, controller, element, payeePickerOutlet;

  beforeEach(() => {
    element = document.createElement("form");

    payeePickerOutlet    = { "validate": sinon.fake.returns(true) };
    categoryPickerOutlet = { "validate": sinon.fake.returns(true) };
    accountPickerOutlet  = { "validate": sinon.fake.returns(true) };

    amount = document.createElement("input");
    amount.type  = "text";
    amount.value = "-$10.00";
    amount.classList.add("text-black");

    controller = new TransactionFormController({
      "scope": {
        "element": element,
        "identifier": "transaction-form"
      }
    });
    controller.payeePickerOutlet    = payeePickerOutlet;
    controller.categoryPickerOutlet = categoryPickerOutlet;
    controller.accountPickerOutlet  = accountPickerOutlet;
    controller.amountTarget         = amount;
  });

  describe("#validate", () => {
    it("validates each picker outlet", () => {
      const event = { "preventDefault": sinon.fake() };

      controller.validate(event);

      expect(payeePickerOutlet.validate).to.have.been.called;
      expect(categoryPickerOutlet.validate).to.have.been.called;
      expect(accountPickerOutlet.validate).to.have.been.called;
    });

    it("does not prevent the submit when every field is valid", () => {
      const event = { "preventDefault": sinon.fake() };

      controller.validate(event);

      expect(event.preventDefault).not.to.have.been.called;
    });

    it("prevents the submit when the payee picker is empty", () => {
      payeePickerOutlet.validate = sinon.fake.returns(false);

      const event = { "preventDefault": sinon.fake() };

      controller.validate(event);

      expect(event.preventDefault).to.have.been.called;
    });

    it("prevents the submit when the category picker is empty", () => {
      categoryPickerOutlet.validate = sinon.fake.returns(false);

      const event = { "preventDefault": sinon.fake() };

      controller.validate(event);

      expect(event.preventDefault).to.have.been.called;
    });

    it("prevents the submit when the account picker is empty", () => {
      accountPickerOutlet.validate = sinon.fake.returns(false);

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
      amount.value = "$0.00";

      const event = { "preventDefault": sinon.fake() };

      controller.validate(event);

      expect(event.preventDefault).to.have.been.called;
      expect(amount.classList.contains("text-red-700")).to.be.true;
      expect(amount.classList.contains("text-black")).to.be.false;
    });

    it("does not change the amount color when the amount is valid", () => {
      amount.value = "-$10.00";

      controller.validate({ "preventDefault": sinon.fake() });

      expect(amount.classList.contains("text-red-700")).to.be.false;
      expect(amount.classList.contains("text-black")).to.be.true;
    });

    it("validates every field even when an earlier field is invalid", () => {
      payeePickerOutlet.validate    = sinon.fake.returns(false);
      categoryPickerOutlet.validate = sinon.fake.returns(false);
      accountPickerOutlet.validate  = sinon.fake.returns(false);
      amount.value                  = "$0.00";

      controller.validate({ "preventDefault": sinon.fake() });

      expect(payeePickerOutlet.validate).to.have.been.called;
      expect(categoryPickerOutlet.validate).to.have.been.called;
      expect(accountPickerOutlet.validate).to.have.been.called;
      expect(amount.classList.contains("text-red-700")).to.be.true;
    });
  });
});
