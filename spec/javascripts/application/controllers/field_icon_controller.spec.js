import FieldIconController from "@app/controllers/field_icon_controller.js";

describe("FieldIconController", () => {
  let controller, element, icon, input;

  beforeEach(() => {
    icon = document.createElement("svg");
    icon.classList.add("text-taupe-400");

    input = document.createElement("input");
    input.value = "";

    element = document.createElement("div");
    element.appendChild(icon);
    element.appendChild(input);

    controller = new FieldIconController({
      "scope": { element }
    });
    controller.iconTarget = icon;
  });

  describe("#connect", () => {
    it("shows the muted icon when the field is empty", () => {
      controller.connect();

      expect(icon.classList.contains("text-taupe-400")).to.be.true;
      expect(icon.classList.contains("text-indigo-600")).to.be.false;
    });

    it("shows the active icon when the field has a value", () => {
      input.value = "Test";

      controller.connect();

      expect(icon.classList.contains("text-taupe-400")).to.be.false;
      expect(icon.classList.contains("text-indigo-600")).to.be.true;
    });
  });

  describe("#update", () => {
    it("switches to active when the field is filled", () => {
      controller.connect();
      input.value = "Test";

      controller.update();

      expect(icon.classList.contains("text-taupe-400")).to.be.false;
      expect(icon.classList.contains("text-indigo-600")).to.be.true;
    });

    it("switches to muted when the field is cleared", () => {
      input.value = "Test";
      controller.connect();
      input.value = "";

      controller.update();

      expect(icon.classList.contains("text-taupe-400")).to.be.true;
      expect(icon.classList.contains("text-indigo-600")).to.be.false;
    });

    it("treats blank strings as empty", () => {
      input.value = "   ";

      controller.update();

      expect(icon.classList.contains("text-taupe-400")).to.be.true;
      expect(icon.classList.contains("text-indigo-600")).to.be.false;
    });

    it("works with select elements", () => {
      element.removeChild(input);

      const select = document.createElement("select");
      const option = document.createElement("option");
      option.value = "option-1";
      option.text = "Option 1";
      select.appendChild(option);
      select.value = "option-1";
      element.appendChild(select);

      controller.update();

      expect(icon.classList.contains("text-taupe-400")).to.be.false;
      expect(icon.classList.contains("text-indigo-600")).to.be.true;
    });
  });

  describe("#focus", () => {
    it("calls showPicker on the field when available", () => {
      input.showPicker = sinon.fake();

      controller.focus({ "target": icon });

      expect(input.showPicker).to.have.been.calledOnce;
    });

    it("falls back to focus when showPicker is not available", () => {
      document.body.appendChild(element);
      controller.focus({ "target": icon });

      expect(document.activeElement).to.eq(input);

      document.body.removeChild(element);
    });

    it("does nothing when the field itself is clicked", () => {
      input.showPicker = sinon.fake();

      controller.focus({ "target": input });

      expect(input.showPicker).not.to.have.been.called;
    });
  });
});
