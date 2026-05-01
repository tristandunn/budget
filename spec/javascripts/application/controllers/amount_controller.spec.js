import AmountController from "@app/controllers/amount_controller.js";

describe("AmountController", () => {
  let element, instance;

  function createPasteEvent(text) {
    const event = new window.Event("paste", { "cancelable": true });

    event.clipboardData = { "getData": () => {
      return text;
    } };

    return event;
  }

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
          "cancelable": true,
          "key": "-"
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

    describe("when pressing +", () => {
      let event;

      beforeEach(() => {
        event = new window.KeyboardEvent("keydown", {
          "cancelable": true,
          "key": "+"
        });
      });

      it("makes a negative value positive", () => {
        element.value = "-42.50";

        instance.keydown(event);

        expect(parseFloat(element.value)).to.eq(42.5);
      });

      it("keeps a positive value positive", () => {
        element.value = "42.50";

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

      it("applies black text when made positive", () => {
        element.value = "-42.50";

        instance.keydown(event);

        expect(element.classList.contains("text-black")).to.eq(true);
        expect(element.classList.contains("text-red-600")).to.eq(false);
      });
    });

    describe("when pressing a digit and value is zero", () => {
      let event;

      beforeEach(() => {
        event = new window.KeyboardEvent("keydown", {
          "cancelable": true,
          "key": "5"
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

    describe("when pressing a digit and value is empty", () => {
      let event;

      beforeEach(() => {
        event = new window.KeyboardEvent("keydown", {
          "cancelable": true,
          "key": "5"
        });

        element.value = "";
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

    describe("when pressing a digit after pressing +", () => {
      it("does not negate the digit", () => {
        element.value = "";

        const plusEvent = new window.KeyboardEvent("keydown", {
          "cancelable": true,
          "key": "+"
        });

        instance.keydown(plusEvent);

        const digitEvent = new window.KeyboardEvent("keydown", {
          "cancelable": true,
          "key": "5"
        });

        instance.keydown(digitEvent);

        expect(element.value).to.eq("5");
      });
    });

    describe("when pressing a digit and value is non-zero", () => {
      let event;

      beforeEach(() => {
        event = new window.KeyboardEvent("keydown", {
          "cancelable": true,
          "key": "5"
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
          "cancelable": true,
          "key": "."
        });

        instance.keydown(event);

        expect(event.defaultPrevented).to.eq(false);
      });

      it("allows backspace", () => {
        const event = new window.KeyboardEvent("keydown", {
          "cancelable": true,
          "key": "Backspace"
        });

        instance.keydown(event);

        expect(event.defaultPrevented).to.eq(false);
      });

      it("allows control shortcuts", () => {
        const event = new window.KeyboardEvent("keydown", {
          "cancelable": true,
          "ctrlKey": true,
          "key": "c"
        });

        instance.keydown(event);

        expect(event.defaultPrevented).to.eq(false);
      });

      it("allows meta shortcuts", () => {
        const event = new window.KeyboardEvent("keydown", {
          "cancelable": true,
          "key": "c",
          "metaKey": true
        });

        instance.keydown(event);

        expect(event.defaultPrevented).to.eq(false);
      });

      it("does not allow letters", () => {
        const event = new window.KeyboardEvent("keydown", {
          "cancelable": true,
          "key": "a"
        });

        instance.keydown(event);

        expect(event.defaultPrevented).to.eq(true);
      });

      it("does not allow symbols", () => {
        const event = new window.KeyboardEvent("keydown", {
          "cancelable": true,
          "key": "$"
        });

        instance.keydown(event);

        expect(event.defaultPrevented).to.eq(true);
      });
    });

    describe("when pasting a value", () => {
      it("extracts the numeric value and defaults to negative", () => {
        const event = createPasteEvent("$42.50");

        instance.paste(event);

        expect(element.value).to.eq("-42.50");
      });

      it("handles values with commas", () => {
        const event = createPasteEvent("1,234.56");

        instance.paste(event);

        expect(element.value).to.eq("-1234.56");
      });

      it("handles plain numeric values", () => {
        const event = createPasteEvent("99.99");

        instance.paste(event);

        expect(element.value).to.eq("-99.99");
      });

      it("handles values with no decimal", () => {
        const event = createPasteEvent("50");

        instance.paste(event);

        expect(element.value).to.eq("-50.00");
      });

      it("keeps value positive when positive mode is active", () => {
        const plusEvent = new window.KeyboardEvent("keydown", {
          "cancelable": true,
          "key": "+"
        });

        instance.keydown(plusEvent);

        const event = createPasteEvent("42.50");

        instance.paste(event);

        expect(element.value).to.eq("42.50");
      });

      it("ignores non-numeric content", () => {
        const event = createPasteEvent("abc");

        instance.paste(event);

        expect(element.value).to.eq("0.00");
      });

      it("prevents the default behavior", () => {
        const event = createPasteEvent("42.50");

        instance.paste(event);

        expect(event.defaultPrevented).to.eq(true);
      });

      it("applies red text for negative values", () => {
        const event = createPasteEvent("42.50");

        instance.paste(event);

        expect(element.classList.contains("text-red-600")).to.eq(true);
        expect(element.classList.contains("text-black")).to.eq(false);
      });

      it("applies black text for positive values", () => {
        const plusEvent = new window.KeyboardEvent("keydown", {
          "cancelable": true,
          "key": "+"
        });

        instance.keydown(plusEvent);

        const event = createPasteEvent("42.50");

        instance.paste(event);

        expect(element.classList.contains("text-black")).to.eq(true);
        expect(element.classList.contains("text-red-600")).to.eq(false);
      });
    });

    describe("when pressing a non-digit, non-minus key", () => {
      let event;

      beforeEach(() => {
        event = new window.KeyboardEvent("keydown", {
          "cancelable": true,
          "key": "Enter"
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

  describe("when positive mode is active", () => {
    beforeEach(() => {
      element.dataset.amountPositiveValue = "true";
    });

    it("rejects the - key", () => {
      element.value = "42.50";

      const event = new window.KeyboardEvent("keydown", {
        "cancelable": true,
        "key": "-"
      });

      instance.keydown(event);

      expect(event.defaultPrevented).to.eq(true);
      expect(element.value).to.eq("42.50");
    });

    it("rejects the + key", () => {
      element.value = "-42.50";

      const event = new window.KeyboardEvent("keydown", {
        "cancelable": true,
        "key": "+"
      });

      instance.keydown(event);

      expect(event.defaultPrevented).to.eq(true);
      expect(element.value).to.eq("-42.50");
    });

    it("does not apply red text on connect when value is negative", () => {
      element.value = "-42.50";

      instance.connect();

      expect(element.classList.contains("text-red-600")).to.eq(false);
      expect(element.classList.contains("text-black")).to.eq(true);
    });

    it("does not apply red text on input when value is negative", () => {
      element.value = "-42.50";

      instance.input();

      expect(element.classList.contains("text-red-600")).to.eq(false);
      expect(element.classList.contains("text-black")).to.eq(true);
    });

    it("coerces a pasted value to positive", () => {
      instance.connect();

      const event = createPasteEvent("$42.50");

      instance.paste(event);

      expect(element.value).to.eq("42.50");
    });

    it("uses the unsigned digit when pressing a digit on a zero value", () => {
      instance.connect();

      const event = new window.KeyboardEvent("keydown", {
        "cancelable": true,
        "key": "5"
      });

      instance.keydown(event);

      expect(element.value).to.eq("5");
    });
  });
});
