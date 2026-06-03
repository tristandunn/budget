import ArithmeticController from "@app/controllers/arithmetic_controller.js";

describe("ArithmeticController", () => {
  let element, instance;

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

      it("appends + when the expression starts with zero", () => {
        element.value = "0.00+50.00";

        instance.keydown(event);

        expect(element.value).to.eq("0.00+50.00+");
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
    });
  });
});
