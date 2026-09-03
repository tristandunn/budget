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
      expect(element.classList.contains("text-red-700")).to.eq(false);
    });

    it("applies black text when value is positive", () => {
      element.value = "42.50";

      instance.connect();

      expect(element.classList.contains("text-black")).to.eq(true);
      expect(element.classList.contains("text-red-700")).to.eq(false);
    });

    it("applies red text when value is negative", () => {
      element.value = "-42.50";

      instance.connect();

      expect(element.classList.contains("text-red-700")).to.eq(true);
      expect(element.classList.contains("text-black")).to.eq(false);
    });

    it("preserves the positive sign on a subsequent paste", () => {
      element.value = "42.50";

      instance.connect();

      const event = createPasteEvent("1234");

      instance.paste(event);

      expect(element.value).to.eq("$1,234");
    });

    it("preserves the positive sign when clearing and typing a digit", () => {
      element.value = "42.50";

      instance.connect();

      element.value = "";

      const event = new window.KeyboardEvent("keydown", {
        "cancelable": true,
        "key": "5"
      });

      instance.keydown(event);

      expect(element.value).to.eq("$5");
    });

    it("preserves the negative sign when selecting all and typing a digit", () => {
      element.value = "-42.50";

      instance.connect();
      instance.element.setSelectionRange(0, instance.element.value.length);

      const event = new window.KeyboardEvent("keydown", {
        "cancelable": true,
        "key": "5"
      });

      instance.keydown(event);

      expect(element.value).to.eq("-$5");
    });
  });

  describe("#input", () => {
    it("applies black text when value is positive", () => {
      element.value = "10.00";

      instance.input();

      expect(element.classList.contains("text-black")).to.eq(true);
      expect(element.classList.contains("text-red-700")).to.eq(false);
    });

    it("applies red text when value is negative", () => {
      element.value = "-10.00";

      instance.input();

      expect(element.classList.contains("text-red-700")).to.eq(true);
      expect(element.classList.contains("text-black")).to.eq(false);
    });

    it("keeps the value negative when a digit is typed before the minus sign", () => {
      element.value = "5-$1,234.56";

      instance.input();

      expect(element.value).to.eq("-$51,234.56");
    });

    it("preserves the cursor position when typing in the middle of the value", () => {
      element.value = "$1,2534.56";
      element.setSelectionRange(5, 5);

      instance.input();

      expect(element.value).to.eq("$12,534.56");
      expect(element.selectionStart).to.eq(5);
    });

    it("preserves the cursor position when typing past a new comma", () => {
      element.value = "$999,9999";
      element.setSelectionRange(9, 9);

      instance.input();

      expect(element.value).to.eq("$9,999,999");
      expect(element.selectionStart).to.eq(10);
    });

    it("places the cursor after the dollar sign when there are no digits before it", () => {
      element.value = "$.";
      element.setSelectionRange(1, 1);

      instance.input();

      expect(element.value).to.eq("$0.");
      expect(element.selectionStart).to.eq(1);
    });

    it("clears the value when only the dollar sign remains", () => {
      element.value = "$";
      element.setSelectionRange(1, 1);

      instance.input();

      expect(element.value).to.eq("");
      expect(element.selectionStart).to.eq(0);
    });

    it("clears the value when only a negative dollar sign remains", () => {
      element.value = "-$";
      element.setSelectionRange(2, 2);

      instance.input();

      expect(element.value).to.eq("");
      expect(element.selectionStart).to.eq(0);
    });

    it("places the cursor at the end when the formatted value has fewer typed characters", () => {
      element.value = "00";
      element.setSelectionRange(2, 2);

      instance.input();

      expect(element.value).to.eq("$0");
      expect(element.selectionStart).to.eq(2);
    });

    it("truncates to two decimal places", () => {
      element.value = "1.5678";
      element.setSelectionRange(6, 6);

      instance.input();

      expect(element.value).to.eq("$1.56");
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

        expect(element.value).to.eq("-$42.50");
      });

      it("toggles a negative value to positive", () => {
        element.value = "-42.50";

        instance.keydown(event);

        expect(element.value).to.eq("$42.50");
      });

      it("keeps an empty value blank", () => {
        element.value = "";

        instance.keydown(event);

        expect(element.value).to.eq("");
      });

      it("prevents the default behavior", () => {
        instance.keydown(event);

        expect(event.defaultPrevented).to.eq(true);
      });

      it("applies red text when toggled to negative", () => {
        element.value = "42.50";

        instance.keydown(event);

        expect(element.classList.contains("text-red-700")).to.eq(true);
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

        expect(element.value).to.eq("$42.50");
      });

      it("keeps a positive value positive", () => {
        element.value = "42.50";

        instance.keydown(event);

        expect(element.value).to.eq("$42.50");
      });

      it("keeps an empty value blank", () => {
        element.value = "";

        instance.keydown(event);

        expect(element.value).to.eq("");
      });

      it("prevents the default behavior", () => {
        instance.keydown(event);

        expect(event.defaultPrevented).to.eq(true);
      });

      it("applies black text when made positive", () => {
        element.value = "-42.50";

        instance.keydown(event);

        expect(element.classList.contains("text-black")).to.eq(true);
        expect(element.classList.contains("text-red-700")).to.eq(false);
      });
    });

    describe("when pressing a digit and value is zero", () => {
      let event;

      beforeEach(() => {
        event = new window.KeyboardEvent("keydown", {
          "cancelable": true,
          "key": "5"
        });

        element.value = "0";
      });

      it("replaces the value with the negative digit", () => {
        instance.keydown(event);

        expect(element.value).to.eq("-$5");
      });

      it("prevents the default behavior", () => {
        instance.keydown(event);

        expect(event.defaultPrevented).to.eq(true);
      });

      it("applies red text after replacing", () => {
        instance.keydown(event);

        expect(element.classList.contains("text-red-700")).to.eq(true);
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

        expect(element.value).to.eq("-$5");
      });

      it("prevents the default behavior", () => {
        instance.keydown(event);

        expect(event.defaultPrevented).to.eq(true);
      });

      it("applies red text after replacing", () => {
        instance.keydown(event);

        expect(element.classList.contains("text-red-700")).to.eq(true);
      });
    });

    describe("when pressing a digit and the value is a zero with a decimal point", () => {
      let event;

      beforeEach(() => {
        event = new window.KeyboardEvent("keydown", {
          "cancelable": true,
          "key": "5"
        });
      });

      it("appends to a trailing decimal point instead of replacing", () => {
        element.value = "$0.";

        instance.keydown(event);

        expect(event.defaultPrevented).to.eq(false);
      });

      it("appends to a zero fraction instead of replacing", () => {
        element.value = "$0.0";

        instance.keydown(event);

        expect(event.defaultPrevented).to.eq(false);
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

        expect(element.value).to.eq("$5");
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

        expect(element.value).to.eq("-$42.50");
      });

      it("handles values with commas", () => {
        const event = createPasteEvent("1,234.56");

        instance.paste(event);

        expect(element.value).to.eq("-$1,234.56");
      });

      it("handles plain numeric values", () => {
        const event = createPasteEvent("99.99");

        instance.paste(event);

        expect(element.value).to.eq("-$99.99");
      });

      it("handles values with no decimal", () => {
        const event = createPasteEvent("50");

        instance.paste(event);

        expect(element.value).to.eq("-$50");
      });

      it("keeps value positive when positive mode is active", () => {
        const plusEvent = new window.KeyboardEvent("keydown", {
          "cancelable": true,
          "key": "+"
        });

        instance.keydown(plusEvent);

        const event = createPasteEvent("42.50");

        instance.paste(event);

        expect(element.value).to.eq("$42.50");
      });

      it("clears the value for non-numeric content", () => {
        const event = createPasteEvent("abc");

        instance.paste(event);

        expect(element.value).to.eq("");
      });

      it("prevents the default behavior", () => {
        const event = createPasteEvent("42.50");

        instance.paste(event);

        expect(event.defaultPrevented).to.eq(true);
      });

      it("applies red text for negative values", () => {
        const event = createPasteEvent("42.50");

        instance.paste(event);

        expect(element.classList.contains("text-red-700")).to.eq(true);
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
        expect(element.classList.contains("text-red-700")).to.eq(false);
      });

      it("switches to negative when the pasted value has a minus sign", () => {
        element.value = "42.50";

        instance.connect();

        const event = createPasteEvent("-1234");

        instance.paste(event);

        expect(element.value).to.eq("-$1,234");
      });

      it("switches to positive when the pasted value has a plus sign", () => {
        element.value = "-42.50";

        instance.connect();

        const event = createPasteEvent("+1234");

        instance.paste(event);

        expect(element.value).to.eq("$1,234");
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
      instance.positiveValue = true;
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

      expect(element.classList.contains("text-red-700")).to.eq(false);
      expect(element.classList.contains("text-black")).to.eq(true);
    });

    it("does not apply red text on input when value is negative", () => {
      element.value = "-42.50";

      instance.input();

      expect(element.classList.contains("text-red-700")).to.eq(false);
      expect(element.classList.contains("text-black")).to.eq(true);
    });

    it("coerces a pasted value to positive", () => {
      instance.connect();

      const event = createPasteEvent("$42.50");

      instance.paste(event);

      expect(element.value).to.eq("$42.50");
    });

    it("uses the unsigned digit when pressing a digit on a zero value", () => {
      element.value = "0";

      instance.connect();

      const event = new window.KeyboardEvent("keydown", {
        "cancelable": true,
        "key": "5"
      });

      instance.keydown(event);

      expect(element.value).to.eq("$5");
    });
  });

  describe("when the value is empty or only a sign", () => {
    it("leaves an empty value blank so the placeholder remains visible", () => {
      element.value = "";

      instance.connect();

      expect(element.value).to.eq("");
    });

    it("leaves a lone minus sign blank", () => {
      element.value = "-";

      instance.connect();

      expect(element.value).to.eq("");
    });
  });

  describe("when the value is zero or only a decimal point", () => {
    it("formats a lone zero without decimals", () => {
      element.value = "0";

      instance.connect();

      expect(element.value).to.eq("$0");
    });

    it("keeps a lone decimal point so a fraction can be typed", () => {
      element.value = ".";

      instance.connect();

      expect(element.value).to.eq("$0.");
    });
  });

  describe("when pressing the decimal point key", () => {
    let event;

    beforeEach(() => {
      event = new window.KeyboardEvent("keydown", {
        "cancelable": true,
        "key": "."
      });

      element.value = "";
    });

    it("starts the fraction with a leading zero", () => {
      instance.keydown(event);

      expect(event.defaultPrevented).to.eq(true);
      expect(element.value).to.eq("-$0.");
    });

    it("keeps the value negative so the sign survives the fraction", () => {
      instance.keydown(event);

      element.value = `${element.value}5`;

      instance.input();

      expect(element.value).to.eq("-$0.5");
    });

    it("uses no sign after pressing +", () => {
      const plusEvent = new window.KeyboardEvent("keydown", {
        "cancelable": true,
        "key": "+"
      });

      instance.keydown(plusEvent);
      instance.keydown(event);

      expect(element.value).to.eq("$0.");
    });

    it("replaces a fully selected value", () => {
      element.value = "42.50";
      instance.element.setSelectionRange(0, element.value.length);

      instance.keydown(event);

      expect(element.value).to.eq("-$0.");
    });
  });

  describe("when restoring the cursor in a value without an integer part", () => {
    it("places the cursor inside the fraction", () => {
      element.value = "$.";
      element.setSelectionRange(2, 2);

      instance.input();

      expect(element.value).to.eq("$0.");
      expect(element.selectionStart).to.eq(3);
    });

    it("keeps the cursor after a digit typed into the fraction", () => {
      element.value = "$0.5";
      element.setSelectionRange(4, 4);

      instance.input();

      expect(element.value).to.eq("$0.5");
      expect(element.selectionStart).to.eq(4);
    });

    it("places the cursor after a fraction that was pasted in", () => {
      element.value = ".5";
      element.setSelectionRange(2, 2);

      instance.input();

      expect(element.value).to.eq("$0.5");
      expect(element.selectionStart).to.eq(4);
    });
  });

  describe("when formatting an amount below a dollar", () => {
    it("formats the completed fraction", () => {
      element.value = "$0.50";

      instance.input();

      expect(element.value).to.eq("$0.50");
    });

    it("keeps the sign on a negative fraction", () => {
      element.value = "-$0.5";

      instance.input();

      expect(element.value).to.eq("-$0.5");
    });
  });

  describe("when the value lacks an integer part", () => {
    it("formats with a leading zero", () => {
      element.value = ".5";

      instance.connect();

      expect(element.value).to.eq("$0.5");
    });
  });

  describe("when the value has only the formatted prefix", () => {
    it("leaves a positive value blank", () => {
      element.value = "$";

      instance.connect();

      expect(element.value).to.eq("");
    });

    it("leaves a negative value blank", () => {
      element.value = "-$";

      instance.connect();

      expect(element.value).to.eq("");
    });
  });

  describe("when used inside a form", () => {
    let form;

    function dispatchFormdata(formData) {
      const event = new window.Event("formdata");

      event.formData = formData;
      form.dispatchEvent(event);
    }

    beforeEach(() => {
      element.name = "amount";

      form = document.createElement("form");

      form.appendChild(element);
      form.addEventListener("submit", (event) => {
        event.preventDefault();
      });

      document.body.appendChild(form);
    });


    it("submits the unformatted value", () => {
      element.value = "-1234.56";

      instance.connect();

      const formData = new window.FormData();

      dispatchFormdata(formData);

      expect(formData.get("amount")).to.eq("-1234.56");
    });

    it("leaves the displayed value formatted when the submission is prevented", () => {
      element.value = "-1234.56";

      instance.connect();

      form.dispatchEvent(new window.Event("submit", { "bubbles": true,
        "cancelable": true }));

      expect(element.value).to.eq("-$1,234.56");
    });

    it("removes the formdata listener on disconnect", () => {
      element.value = "-1234.56";

      instance.connect();
      instance.disconnect();

      const formData = new window.FormData();

      formData.set("amount", element.value);
      dispatchFormdata(formData);

      expect(formData.get("amount")).to.eq("-$1,234.56");
    });
  });
});
