import ArithmeticController from "@app/controllers/arithmetic_controller.js";

describe("ArithmeticController", () => {
  let element, instance;

  function createPasteEvent(text) {
    const event = new window.Event("paste", { "cancelable": true });

    event.clipboardData = {
      "getData": () => {
        return text;
      }
    };

    return event;
  }

  beforeEach(() => {
    element = document.createElement("input");
    element.value = "100.00";

    instance = new ArithmeticController({ "scope": { element } });
  });

  describe("#keydown", () => {
    describe("when pressing +", () => {
      let event;

      beforeEach(() => {
        event = new window.KeyboardEvent("keydown", {
          "cancelable": true,
          "key": "+"
        });
      });

      it("appends + to a non-zero value", () => {
        instance.keydown(event);

        expect(element.value).to.eq("100.00+");
      });

      it("places the cursor at the end", () => {
        document.body.appendChild(element);

        instance.keydown(event);

        expect(element.selectionStart).to.eq(7);
        expect(element.selectionEnd).to.eq(7);

        document.body.removeChild(element);
      });

      it("prevents the default behavior", () => {
        instance.keydown(event);

        expect(event.defaultPrevented).to.eq(true);
      });

      it("is ignored when value is empty", () => {
        element.value = "";

        instance.keydown(event);

        expect(element.value).to.eq("");
      });

      it("is ignored when value is zero", () => {
        element.value = "0.00";

        instance.keydown(event);

        expect(element.value).to.eq("0.00");
      });

      it("is ignored when value is a bare minus sign", () => {
        element.value = "-";

        instance.keydown(event);

        expect(element.value).to.eq("-");
      });

      it("refuses a second operator when the expression starts with zero", () => {
        element.value = "0.00+50.00";

        instance.keydown(event);

        expect(element.value).to.eq("0.00+50.00");
      });

      it("refuses a second operator", () => {
        element.value = "-50+20";

        instance.keydown(event);

        expect(element.value).to.eq("-50+20");
      });

      it("keeps the cursor in place when refusing a second operator", () => {
        document.body.appendChild(element);

        element.value = "-50+20";
        element.setSelectionRange(2, 2);

        instance.keydown(event);

        expect(element.selectionStart).to.eq(2);
        expect(element.selectionEnd).to.eq(2);

        document.body.removeChild(element);
      });

      it("appends + after a leading minus sign", () => {
        element.value = "-50";

        instance.keydown(event);

        expect(element.value).to.eq("-50+");
      });

      it("replaces a trailing + operator", () => {
        element.value = "100.00+";

        instance.keydown(event);

        expect(element.value).to.eq("100.00+");
      });

      it("replaces a trailing - operator", () => {
        element.value = "100.00-";

        instance.keydown(event);

        expect(element.value).to.eq("100.00+");
      });
    });

    describe("when pressing -", () => {
      let event;

      beforeEach(() => {
        event = new window.KeyboardEvent("keydown", {
          "cancelable": true,
          "key": "-"
        });
      });

      it("appends - to a non-zero value", () => {
        instance.keydown(event);

        expect(element.value).to.eq("100.00-");
      });

      it("prevents the default behavior", () => {
        instance.keydown(event);

        expect(event.defaultPrevented).to.eq(true);
      });

      it("replaces the value with - when empty", () => {
        element.value = "";

        instance.keydown(event);

        expect(element.value).to.eq("-");
      });

      it("replaces the value with - when zero", () => {
        element.value = "0.00";

        instance.keydown(event);

        expect(element.value).to.eq("-");
      });

      it("replaces a trailing + operator", () => {
        element.value = "100.00+";

        instance.keydown(event);

        expect(element.value).to.eq("100.00-");
      });

      it("replaces a trailing - operator", () => {
        element.value = "100.00-";

        instance.keydown(event);

        expect(element.value).to.eq("100.00-");
      });

      it("refuses a second operator", () => {
        element.value = "-50+20";

        instance.keydown(event);

        expect(element.value).to.eq("-50+20");
      });

      it("appends - after a leading minus sign", () => {
        element.value = "-50";

        instance.keydown(event);

        expect(element.value).to.eq("-50-");
      });

      it("keeps a bare minus sign", () => {
        element.value = "-";

        instance.keydown(event);

        expect(element.value).to.eq("-");
      });
    });

    describe("when pressing *", () => {
      let event;

      beforeEach(() => {
        event = new window.KeyboardEvent("keydown", {
          "cancelable": true,
          "key": "*"
        });
      });

      it("appends * to a non-zero value", () => {
        instance.keydown(event);

        expect(element.value).to.eq("100.00*");
      });

      it("places the cursor at the end", () => {
        document.body.appendChild(element);

        instance.keydown(event);

        expect(element.selectionStart).to.eq(7);
        expect(element.selectionEnd).to.eq(7);

        document.body.removeChild(element);
      });

      it("prevents the default behavior", () => {
        instance.keydown(event);

        expect(event.defaultPrevented).to.eq(true);
      });

      it("is ignored when value is empty", () => {
        element.value = "";

        instance.keydown(event);

        expect(element.value).to.eq("");
      });

      it("is ignored when value is zero", () => {
        element.value = "0.00";

        instance.keydown(event);

        expect(element.value).to.eq("0.00");
      });

      it("is ignored when value is a bare minus sign", () => {
        element.value = "-";

        instance.keydown(event);

        expect(element.value).to.eq("-");
      });

      it("is ignored when value is a bare plus sign", () => {
        element.value = "+";

        instance.keydown(event);

        expect(element.value).to.eq("+");
      });

      it("refuses a second operator", () => {
        element.value = "-50*20";

        instance.keydown(event);

        expect(element.value).to.eq("-50*20");
      });

      it("appends * after a leading minus sign", () => {
        element.value = "-50";

        instance.keydown(event);

        expect(element.value).to.eq("-50*");
      });

      it("replaces a trailing + operator", () => {
        element.value = "100.00+";

        instance.keydown(event);

        expect(element.value).to.eq("100.00*");
      });

      it("replaces a trailing / operator", () => {
        element.value = "100.00/";

        instance.keydown(event);

        expect(element.value).to.eq("100.00*");
      });
    });

    describe("when pressing /", () => {
      let event;

      beforeEach(() => {
        event = new window.KeyboardEvent("keydown", {
          "cancelable": true,
          "key": "/"
        });
      });

      it("appends / to a non-zero value", () => {
        instance.keydown(event);

        expect(element.value).to.eq("100.00/");
      });

      it("places the cursor at the end", () => {
        document.body.appendChild(element);

        instance.keydown(event);

        expect(element.selectionStart).to.eq(7);
        expect(element.selectionEnd).to.eq(7);

        document.body.removeChild(element);
      });

      it("prevents the default behavior", () => {
        instance.keydown(event);

        expect(event.defaultPrevented).to.eq(true);
      });

      it("is ignored when value is empty", () => {
        element.value = "";

        instance.keydown(event);

        expect(element.value).to.eq("");
      });

      it("is ignored when value is zero", () => {
        element.value = "0.00";

        instance.keydown(event);

        expect(element.value).to.eq("0.00");
      });

      it("is ignored when value is a bare minus sign", () => {
        element.value = "-";

        instance.keydown(event);

        expect(element.value).to.eq("-");
      });

      it("is ignored when value is a bare plus sign", () => {
        element.value = "+";

        instance.keydown(event);

        expect(element.value).to.eq("+");
      });

      it("refuses a second operator", () => {
        element.value = "-50/20";

        instance.keydown(event);

        expect(element.value).to.eq("-50/20");
      });

      it("appends / after a leading minus sign", () => {
        element.value = "-50";

        instance.keydown(event);

        expect(element.value).to.eq("-50/");
      });

      it("replaces a trailing - operator", () => {
        element.value = "100.00-";

        instance.keydown(event);

        expect(element.value).to.eq("100.00/");
      });

      it("replaces a trailing * operator", () => {
        element.value = "100.00*";

        instance.keydown(event);

        expect(element.value).to.eq("100.00/");
      });
    });

    describe("when pressing invalid characters", () => {
      it("blocks letters", () => {
        const event = new window.KeyboardEvent("keydown", {
          "cancelable": true,
          "key": "a"
        });

        instance.keydown(event);

        expect(event.defaultPrevented).to.eq(true);
      });

      it("blocks symbols", () => {
        const event = new window.KeyboardEvent("keydown", {
          "cancelable": true,
          "key": "$"
        });

        instance.keydown(event);

        expect(event.defaultPrevented).to.eq(true);
      });
    });

    describe("when pressing valid characters", () => {
      it("allows digits", () => {
        const event = new window.KeyboardEvent("keydown", {
          "cancelable": true,
          "key": "5"
        });

        instance.keydown(event);

        expect(event.defaultPrevented).to.eq(false);
      });

      it("allows the decimal point", () => {
        const event = new window.KeyboardEvent("keydown", {
          "cancelable": true,
          "key": "."
        });

        instance.keydown(event);

        expect(event.defaultPrevented).to.eq(false);
      });
    });

    describe("when pressing special keys", () => {
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

      it("allows control shortcuts using an operator", () => {
        const event = new window.KeyboardEvent("keydown", {
          "cancelable": true,
          "ctrlKey": true,
          "key": "-"
        });

        instance.keydown(event);

        expect(element.value).to.eq("100.00");
        expect(event.defaultPrevented).to.eq(false);
      });

      it("allows meta shortcuts using an operator", () => {
        const event = new window.KeyboardEvent("keydown", {
          "cancelable": true,
          "key": "-",
          "metaKey": true
        });

        instance.keydown(event);

        expect(element.value).to.eq("100.00");
        expect(event.defaultPrevented).to.eq(false);
      });
    });
  });

  describe("#paste", () => {
    beforeEach(() => {
      document.body.appendChild(element);
    });

    afterEach(() => {
      document.body.removeChild(element);
    });

    it("inserts the cleaned value at the cursor", () => {
      element.value = "";
      element.setSelectionRange(0, 0);

      instance.paste(createPasteEvent("123.45"));

      expect(element.value).to.eq("123.45");
    });

    it("keeps digits, decimals, and operators", () => {
      element.value = "";
      element.setSelectionRange(0, 0);

      instance.paste(createPasteEvent("12+3.45"));

      expect(element.value).to.eq("12+3.45");
    });

    it("keeps digits, decimals, and the multiply operator", () => {
      element.value = "";
      element.setSelectionRange(0, 0);

      instance.paste(createPasteEvent("12*3.45"));

      expect(element.value).to.eq("12*3.45");
    });

    it("keeps digits, decimals, and the divide operator", () => {
      element.value = "";
      element.setSelectionRange(0, 0);

      instance.paste(createPasteEvent("12/3.45"));

      expect(element.value).to.eq("12/3.45");
    });

    it("truncates to the first operation", () => {
      element.value = "";
      element.setSelectionRange(0, 0);

      instance.paste(createPasteEvent("12+3-4.5"));

      expect(element.value).to.eq("12+3");
    });

    it("truncates to the first operation when multiplying", () => {
      element.value = "";
      element.setSelectionRange(0, 0);

      instance.paste(createPasteEvent("12*3/4.5"));

      expect(element.value).to.eq("12*3");
    });

    it("keeps a leading minus sign when truncating", () => {
      element.value = "";
      element.setSelectionRange(0, 0);

      instance.paste(createPasteEvent("-50+20+30"));

      expect(element.value).to.eq("-50+20");
    });

    it("strips non-numeric, non-operator characters", () => {
      element.value = "";
      element.setSelectionRange(0, 0);

      instance.paste(createPasteEvent("$1,2a3"));

      expect(element.value).to.eq("123");
    });

    it("replaces the selected range", () => {
      element.value = "100.00";
      element.setSelectionRange(0, 6);

      instance.paste(createPasteEvent("50"));

      expect(element.value).to.eq("50");
    });

    it("places the cursor after the inserted value", () => {
      element.value = "100";
      element.setSelectionRange(3, 3);

      instance.paste(createPasteEvent("+25"));

      expect(element.value).to.eq("100+25");
      expect(element.selectionStart).to.eq(6);
      expect(element.selectionEnd).to.eq(6);
    });

    it("collapses consecutive operators, keeping the last", () => {
      element.value = "";
      element.setSelectionRange(0, 0);

      instance.paste(createPasteEvent("1+-2"));

      expect(element.value).to.eq("1-2");
    });

    it("collapses consecutive operators, keeping a last multiply", () => {
      element.value = "";
      element.setSelectionRange(0, 0);

      instance.paste(createPasteEvent("1+*2"));

      expect(element.value).to.eq("1*2");
    });

    it("collapses consecutive operators, keeping a last divide", () => {
      element.value = "";
      element.setSelectionRange(0, 0);

      instance.paste(createPasteEvent("1*/2"));

      expect(element.value).to.eq("1/2");
    });

    it("collapses operators across the insertion boundary", () => {
      element.value = "100+";
      element.setSelectionRange(4, 4);

      instance.paste(createPasteEvent("+25"));

      expect(element.value).to.eq("100+25");
      expect(element.selectionStart).to.eq(6);
      expect(element.selectionEnd).to.eq(6);
    });

    it("collapses operators across the insertion boundary when dividing", () => {
      element.value = "100*";
      element.setSelectionRange(4, 4);

      instance.paste(createPasteEvent("/25"));

      expect(element.value).to.eq("100/25");
      expect(element.selectionStart).to.eq(6);
      expect(element.selectionEnd).to.eq(6);
    });

    it("collapses operators when inserting before an existing operator", () => {
      element.value = "1+2";
      element.setSelectionRange(1, 1);

      instance.paste(createPasteEvent("5+"));

      expect(element.value).to.eq("15+2");
      expect(element.selectionStart).to.eq(3);
      expect(element.selectionEnd).to.eq(3);
    });

    it("prevents the default behavior", () => {
      const event = createPasteEvent("123");

      instance.paste(event);

      expect(event.defaultPrevented).to.eq(true);
    });
  });
});
