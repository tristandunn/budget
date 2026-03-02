import AmountController from "@app/controllers/amount_controller.js";

describe("AmountController", () => {
  let element, instance;

  beforeEach(() => {
    element = document.createElement("input");
    element.value = "0.00";

    instance = new AmountController({ "scope": { element } });
  });

  describe("#connect", () => {
    it("applies black text when value is zero", () => {
      instance.connect();

      expect(element.classList.contains("text-black")).to.eq(true);
      expect(element.classList.contains("text-red-600")).to.eq(false);
    });

    it("applies black text when value is positive", () => {
      element.value = "42.50";

      instance.connect();

      expect(element.classList.contains("text-black")).to.eq(true);
      expect(element.classList.contains("text-red-600")).to.eq(false);
    });

    it("applies red text when value is negative", () => {
      element.value = "-42.50";

      instance.connect();

      expect(element.classList.contains("text-red-600")).to.eq(true);
      expect(element.classList.contains("text-black")).to.eq(false);
    });
  });

  describe("#input", () => {
    it("applies black text when value is positive", () => {
      element.value = "10.00";

      instance.input();

      expect(element.classList.contains("text-black")).to.eq(true);
      expect(element.classList.contains("text-red-600")).to.eq(false);
    });

    it("applies red text when value is negative", () => {
      element.value = "-10.00";

      instance.input();

      expect(element.classList.contains("text-red-600")).to.eq(true);
      expect(element.classList.contains("text-black")).to.eq(false);
    });
  });

  describe("#keydown", () => {
    describe("when pressing -", () => {
      let event;

      beforeEach(() => {
        event = new window.KeyboardEvent("keydown", {
          "key": "-",
          "cancelable": true
        });
      });

      it("toggles a positive value to negative", () => {
        element.value = "42.50";

        instance.keydown(event);

        expect(parseFloat(element.value)).to.eq(-42.5);
      });

      it("toggles a negative value to positive", () => {
        element.value = "-42.50";

        instance.keydown(event);

        expect(parseFloat(element.value)).to.eq(42.5);
      });

      it("keeps an empty value at zero", () => {
        element.value = "";

        instance.keydown(event);

        expect(parseFloat(element.value)).to.eq(0);
      });

      it("prevents the default behavior", () => {
        instance.keydown(event);

        expect(event.defaultPrevented).to.eq(true);
      });

      it("applies red text when toggled to negative", () => {
        element.value = "42.50";

        instance.keydown(event);

        expect(element.classList.contains("text-red-600")).to.eq(true);
      });

      it("applies black text when toggled to positive", () => {
        element.value = "-42.50";

        instance.keydown(event);

        expect(element.classList.contains("text-black")).to.eq(true);
      });
    });

    describe("when pressing a digit and value is zero", () => {
      let event;

      beforeEach(() => {
        event = new window.KeyboardEvent("keydown", {
          "key": "5",
          "cancelable": true
        });
      });

      it("replaces the value with the negative digit", () => {
        instance.keydown(event);

        expect(element.value).to.eq("-5");
      });

      it("prevents the default behavior", () => {
        instance.keydown(event);

        expect(event.defaultPrevented).to.eq(true);
      });

      it("applies red text after replacing", () => {
        instance.keydown(event);

        expect(element.classList.contains("text-red-600")).to.eq(true);
      });
    });

    describe("when pressing a digit and value is non-zero", () => {
      let event;

      beforeEach(() => {
        event = new window.KeyboardEvent("keydown", {
          "key": "5",
          "cancelable": true
        });

        element.value = "42.50";
      });

      it("does not replace the value", () => {
        instance.keydown(event);

        expect(element.value).to.eq("42.50");
      });

      it("does not prevent the default behavior", () => {
        instance.keydown(event);

        expect(event.defaultPrevented).to.eq(false);
      });
    });

    describe("when pressing an invalid character", () => {
      it("allows the decimal point", () => {
        const event = new window.KeyboardEvent("keydown", {
          "key": ".",
          "cancelable": true
        });

        instance.keydown(event);

        expect(event.defaultPrevented).to.eq(false);
      });

      it("allows backspace", () => {
        const event = new window.KeyboardEvent("keydown", {
          "key": "Backspace",
          "cancelable": true
        });

        instance.keydown(event);

        expect(event.defaultPrevented).to.eq(false);
      });

      it("allows control shortcuts", () => {
        const event = new window.KeyboardEvent("keydown", {
          "key": "c",
          "cancelable": true,
          "ctrlKey": true
        });

        instance.keydown(event);

        expect(event.defaultPrevented).to.eq(false);
      });

      it("allows meta shortcuts", () => {
        const event = new window.KeyboardEvent("keydown", {
          "key": "c",
          "cancelable": true,
          "metaKey": true
        });

        instance.keydown(event);

        expect(event.defaultPrevented).to.eq(false);
      });

      it("does not allow letters", () => {
        const event = new window.KeyboardEvent("keydown", {
          "key": "a",
          "cancelable": true
        });

        instance.keydown(event);

        expect(event.defaultPrevented).to.eq(true);
      });

      it("does not allow symbols", () => {
        const event = new window.KeyboardEvent("keydown", {
          "key": "$",
          "cancelable": true
        });

        instance.keydown(event);

        expect(event.defaultPrevented).to.eq(true);
      });
    });

    describe("when pressing a non-digit, non-minus key", () => {
      let event;

      beforeEach(() => {
        event = new window.KeyboardEvent("keydown", {
          "key": "Enter",
          "cancelable": true
        });

        element.value = "42.50";
      });

      it("does not modify the value", () => {
        instance.keydown(event);

        expect(element.value).to.eq("42.50");
      });

      it("does not prevent the default behavior", () => {
        instance.keydown(event);

        expect(event.defaultPrevented).to.eq(false);
      });
    });
  });
});
