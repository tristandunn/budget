import SelectionController from "@app/controllers/selection_controller.js";

describe("SelectionController", () => {
  let alpha, beta, instance, panelFrame, summary;

  const subcategory = (id, url) => {
    const box = document.createElement("input");
    box.type = "checkbox";
    box.setAttribute("data-selection-target", "subcategory");
    box.dataset.subcategoryId = id;
    box.dataset.detailUrl = url;

    return box;
  };

  const rowFor = (box) => {
    const row = document.createElement("tr");
    row.appendChild(box);

    return row;
  };

  beforeEach(() => {
    alpha = subcategory("1", "/budgets/1/categories/1/panel");
    beta  = subcategory("2", "/budgets/1/categories/2/panel");

    summary = document.createElement("div");

    panelFrame = document.createElement("turbo-frame");
    panelFrame.classList.add("hidden");

    instance = new SelectionController({
      "scope": { "element": document.createElement("div") }
    });
    instance.subcategoryTargets = [alpha, beta];
    instance.panelFrameTarget   = panelFrame;
    instance.summaryTarget      = summary;
    instance.selectedIdsValue   = [];
    instance.summaryUrlValue    = "/budgets/1/categories/summary?year=2026&month=7";
  });

  describe("#toggle", () => {
    it("loads the checked subcategory's detail into the panel frame", () => {
      alpha.checked = true;

      instance.toggle({ "target": alpha });

      expect(panelFrame.getAttribute("src")).to.eq("/budgets/1/categories/1/panel");
    });

    it("reveals the panel and hides the summary when a subcategory is checked", () => {
      alpha.checked = true;

      instance.toggle({ "target": alpha });

      expect(panelFrame.classList.contains("hidden")).to.eq(false);
      expect(summary.classList.contains("hidden")).to.eq(true);
    });

    it("keeps the previously selected subcategory checked", () => {
      alpha.checked = true;
      instance.toggle({ "target": alpha });

      beta.checked = true;
      instance.toggle({ "target": beta });

      expect(alpha.checked).to.eq(true);
      expect(beta.checked).to.eq(true);
    });

    it("loads the summary with every selected id when more than one is selected", () => {
      alpha.checked = true;
      instance.toggle({ "target": alpha });

      beta.checked = true;
      instance.toggle({ "target": beta });

      expect(panelFrame.getAttribute("src")).to.eq(
        "/budgets/1/categories/summary?year=2026&month=7&ids%5B%5D=1&ids%5B%5D=2"
      );
    });

    it("clears the panel frame source when the selection is removed", () => {
      alpha.checked = true;
      instance.toggle({ "target": alpha });

      alpha.checked = false;
      instance.toggle({ "target": alpha });

      expect(panelFrame.hasAttribute("src")).to.eq(false);
    });

    it("hides the panel and restores the summary when the selection is removed", () => {
      alpha.checked = true;
      instance.toggle({ "target": alpha });

      alpha.checked = false;
      instance.toggle({ "target": alpha });

      expect(panelFrame.classList.contains("hidden")).to.eq(true);
      expect(summary.classList.contains("hidden")).to.eq(false);
    });

    it("returns to the single subcategory detail when the selection drops to one", () => {
      alpha.checked = true;
      instance.toggle({ "target": alpha });

      beta.checked = true;
      instance.toggle({ "target": beta });

      beta.checked = false;
      instance.toggle({ "target": beta });

      expect(panelFrame.getAttribute("src")).to.eq("/budgets/1/categories/1/panel");
    });

    it("marks every selected subcategory's row", () => {
      const alphaRow = rowFor(alpha),
            betaRow  = rowFor(beta);

      alpha.checked = true;
      instance.toggle({ "target": alpha });

      beta.checked = true;
      instance.toggle({ "target": beta });

      expect(alphaRow.hasAttribute("data-selected")).to.eq(true);
      expect(betaRow.hasAttribute("data-selected")).to.eq(true);
    });

    it("clears the row highlight when the selection is removed", () => {
      const alphaRow = rowFor(alpha);

      alpha.checked = true;
      instance.toggle({ "target": alpha });

      alpha.checked = false;
      instance.toggle({ "target": alpha });

      expect(alphaRow.hasAttribute("data-selected")).to.eq(false);
    });
  });

  describe("#selectRow", () => {
    it("selects the subcategory in the clicked row", () => {
      rowFor(alpha);

      instance.selectRow({ "target": alpha });

      expect(alpha.checked).to.eq(true);
      expect(panelFrame.getAttribute("src")).to.eq("/budgets/1/categories/1/panel");
    });

    it("switches to only the clicked row during a multiple selection", () => {
      rowFor(alpha);
      rowFor(beta);

      alpha.checked = true;
      instance.toggle({ "target": alpha });

      beta.checked = true;
      instance.toggle({ "target": beta });

      instance.selectRow({ "target": beta });

      expect(alpha.checked).to.eq(false);
      expect(beta.checked).to.eq(true);
      expect(panelFrame.getAttribute("src")).to.eq("/budgets/1/categories/2/panel");
    });

    it("switches to the clicked row when a different single row is selected", () => {
      rowFor(alpha);
      rowFor(beta);

      alpha.checked = true;
      instance.toggle({ "target": alpha });

      instance.selectRow({ "target": beta });

      expect(alpha.checked).to.eq(false);
      expect(beta.checked).to.eq(true);
      expect(panelFrame.getAttribute("src")).to.eq("/budgets/1/categories/2/panel");
    });

    it("does nothing when the row is already the only selection", () => {
      rowFor(alpha);
      alpha.checked = true;

      instance.selectRow({ "target": alpha });

      expect(panelFrame.hasAttribute("src")).to.eq(false);
    });

    it("does nothing when the clicked element has no subcategory row", () => {
      const orphan = document.createElement("td");

      instance.selectRow({ "target": orphan });

      expect(panelFrame.hasAttribute("src")).to.eq(false);
    });
  });

  describe("#subcategoryTargetConnected", () => {
    it("reselects and reloads a replaced row that matches the selection", () => {
      const replacement = subcategory("1", "/budgets/1/categories/1/panel"),
            row         = rowFor(replacement);

      panelFrame.reload = sinon.fake();
      instance.subcategoryTargets = [replacement];
      instance.selectedIdsValue = ["1"];

      instance.subcategoryTargetConnected(replacement);

      expect(replacement.checked).to.eq(true);
      expect(row.hasAttribute("data-selected")).to.eq(true);
      expect(panelFrame.reload).to.have.been.called;
    });

    it("ignores a connected row that is not part of the selection", () => {
      const other = subcategory("2", "/budgets/1/categories/2/panel");
      rowFor(other);

      panelFrame.reload = sinon.fake();
      instance.subcategoryTargets = [other];
      instance.selectedIdsValue = ["1"];

      instance.subcategoryTargetConnected(other);

      expect(other.checked).to.eq(false);
      expect(panelFrame.reload).to.have.callCount(0);
    });

    it("ignores the selected row when it is already checked", () => {
      const box = subcategory("1", "/budgets/1/categories/1/panel");
      box.checked = true;
      rowFor(box);

      panelFrame.reload = sinon.fake();
      instance.subcategoryTargets = [box];
      instance.selectedIdsValue = ["1"];

      instance.subcategoryTargetConnected(box);

      expect(panelFrame.reload).to.have.callCount(0);
    });
  });
});
