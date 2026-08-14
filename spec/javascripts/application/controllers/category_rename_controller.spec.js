import CategoryRenameController from "@app/controllers/category_rename_controller.js";

describe("CategoryRenameController", () => {
  let checkbox, element, frame, instance;

  const open = () => {
    return instance.open(new window.Event("click"));
  };

  beforeEach(() => {
    checkbox = document.createElement("input");
    checkbox.type = "checkbox";

    frame = document.createElement("turbo-frame");

    element = document.createElement("th");
    element.appendChild(checkbox);
    element.appendChild(frame);
    document.body.appendChild(element);

    instance = new CategoryRenameController({ "scope": { element } });
    instance.hasCheckboxTarget = true;
    instance.checkboxTarget    = checkbox;
    instance.frameTarget       = frame;
    instance.urlValue          = "/rename-url";
    instance.connect();
  });

  afterEach(() => {
    instance.disconnect();
    element.remove();
  });

  describe("#open", () => {
    context("when the checkbox is checked", () => {
      let event;

      beforeEach(() => {
        checkbox.checked = true;

        event = new window.Event("click");

        sinon.spy(event, "preventDefault");
        sinon.spy(event, "stopPropagation");
      });

      it("loads the rename form into the frame", () => {
        instance.open(event);

        expect(frame.getAttribute("src")).to.eq("/rename-url");
      });

      it("prevents the default selection behavior", () => {
        instance.open(event);

        expect(event.preventDefault.calledOnce).to.eq(true);
        expect(event.stopPropagation.calledOnce).to.eq(true);
      });

      it("ignores repeat clicks so typed input is kept", () => {
        instance.open(event);

        sinon.spy(frame, "setAttribute");

        open();

        expect(frame.setAttribute.called).to.eq(false);
      });
    });

    context("when the checkbox is unchecked", () => {
      let event;

      beforeEach(() => {
        checkbox.checked = false;

        event = new window.Event("click");

        sinon.spy(event, "preventDefault");
      });

      it("does nothing", () => {
        instance.open(event);

        expect(frame.getAttribute("src")).to.eq(null);
        expect(event.preventDefault.called).to.eq(false);
      });
    });

    context("when there is no checkbox target", () => {
      beforeEach(() => {
        instance.hasCheckboxTarget = false;
      });

      it("loads the frame without a selection gate", () => {
        open();

        expect(frame.getAttribute("src")).to.eq("/rename-url");
      });
    });
  });

  describe("#focus", () => {
    it("focuses the autofocus field within the frame", () => {
      const field = document.createElement("input");
      field.setAttribute("autofocus", "");
      frame.appendChild(field);

      instance.focus();

      expect(document.activeElement).to.eq(field);
    });

    it("does nothing when the frame has no autofocus field", () => {
      expect(() => {
        return instance.focus();
      }).not.to.throw();
    });
  });

  describe("#close", () => {
    beforeEach(() => {
      checkbox.checked = true;

      open();

      frame.setAttribute("complete", "");
      frame.innerHTML = "FORM";
    });

    it("clears the frame so CSS hides it and it refetches next time", () => {
      instance.close();

      expect(frame.getAttribute("src")).to.eq(null);
      expect(frame.hasAttribute("complete")).to.eq(false);
      expect(frame.innerHTML).to.eq("");
    });
  });

  describe("when the menu is open", () => {
    beforeEach(() => {
      checkbox.checked = true;

      open();

      frame.setAttribute("complete", "");
    });

    it("closes when clicking outside the controller", () => {
      document.dispatchEvent(new window.Event("click"));

      expect(frame.hasAttribute("src")).to.eq(false);
    });

    it("ignores clicks within the controller", () => {
      frame.dispatchEvent(new window.Event("click", { "bubbles": true }));

      expect(frame.hasAttribute("src")).to.eq(true);
    });

    it("closes when the escape key is pressed", () => {
      document.dispatchEvent(new window.KeyboardEvent("keydown", { "key": "Escape" }));

      expect(frame.hasAttribute("src")).to.eq(false);
    });

    it("ignores other keys", () => {
      document.dispatchEvent(new window.KeyboardEvent("keydown", { "key": "Enter" }));

      expect(frame.hasAttribute("src")).to.eq(true);
    });

    it("closes before the page is cached", () => {
      document.dispatchEvent(new window.Event("turbo:before-cache"));

      expect(frame.hasAttribute("src")).to.eq(false);
    });
  });
});
