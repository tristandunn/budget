import SelectionController from "@app/controllers/selection_controller.js";

describe("SelectionController", () => {
  let all, alpha, beta, group, instance, panelFrame, summary;

  const selectAll = () => {
    const box = document.createElement("input");
    box.type = "checkbox";
    box.setAttribute("data-selection-target", "all");

    return box;
  };

  const category = (id) => {
    const box = document.createElement("input");
    box.type = "checkbox";
    box.setAttribute("data-selection-target", "category");
    box.dataset.categoryId = id;

    return box;
  };

  const subcategory = (id, url, categoryId = "10") => {
    const box = document.createElement("input");
    box.type = "checkbox";
    box.setAttribute("data-selection-target", "subcategory");
    box.dataset.categoryId = categoryId;
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
    all   = selectAll();
    alpha = subcategory("1", "/budgets/1/categories/1/panel");
    beta  = subcategory("2", "/budgets/1/categories/2/panel");
    group = category("10");

    summary = document.createElement("div");

    panelFrame = document.createElement("turbo-frame");
    panelFrame.classList.add("hidden");

    instance = new SelectionController({
      "scope": { "element": document.createElement("div") }
    });
    instance.allTarget          = all;
    instance.categoryTargets    = [group];
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

    it("checks the category when all of its subcategories are checked", () => {
      alpha.checked = true;
      instance.toggle({ "target": alpha });

      beta.checked = true;
      instance.toggle({ "target": beta });

      expect(group.checked).to.eq(true);
      expect(group.indeterminate).to.eq(false);
    });

    it("marks the category indeterminate when only some subcategories are checked", () => {
      alpha.checked = true;
      instance.toggle({ "target": alpha });

      expect(group.checked).to.eq(false);
      expect(group.indeterminate).to.eq(true);
    });

    it("clears the category when the last subcategory is unchecked", () => {
      alpha.checked = true;
      instance.toggle({ "target": alpha });

      alpha.checked = false;
      instance.toggle({ "target": alpha });

      expect(group.checked).to.eq(false);
      expect(group.indeterminate).to.eq(false);
    });

    it("checks the select-all box when every subcategory is checked", () => {
      alpha.checked = true;
      instance.toggle({ "target": alpha });

      beta.checked = true;
      instance.toggle({ "target": beta });

      expect(all.checked).to.eq(true);
      expect(all.indeterminate).to.eq(false);
    });

    it("marks the select-all box indeterminate when only some are checked", () => {
      alpha.checked = true;
      instance.toggle({ "target": alpha });

      expect(all.checked).to.eq(false);
      expect(all.indeterminate).to.eq(true);
    });
  });

  describe("#toggleAll", () => {
    it("checks every subcategory and loads their summary", () => {
      all.checked = true;

      instance.toggleAll({ "target": all });

      expect(alpha.checked).to.eq(true);
      expect(beta.checked).to.eq(true);
      expect(panelFrame.getAttribute("src")).to.eq(
        "/budgets/1/categories/summary?year=2026&month=7&ids%5B%5D=1&ids%5B%5D=2"
      );
    });

    it("checks every category box when everything is selected", () => {
      all.checked = true;

      instance.toggleAll({ "target": all });

      expect(group.checked).to.eq(true);
      expect(group.indeterminate).to.eq(false);
    });

    it("unchecks every subcategory and restores the summary", () => {
      all.checked = true;
      instance.toggleAll({ "target": all });

      all.checked = false;
      instance.toggleAll({ "target": all });

      expect(alpha.checked).to.eq(false);
      expect(beta.checked).to.eq(false);
      expect(panelFrame.hasAttribute("src")).to.eq(false);
      expect(panelFrame.classList.contains("hidden")).to.eq(true);
      expect(summary.classList.contains("hidden")).to.eq(false);
    });
  });

  describe("#toggleCategory", () => {
    it("checks every subcategory under the category and loads their summary", () => {
      group.checked = true;

      instance.toggleCategory({ "target": group });

      expect(alpha.checked).to.eq(true);
      expect(beta.checked).to.eq(true);
      expect(panelFrame.getAttribute("src")).to.eq(
        "/budgets/1/categories/summary?year=2026&month=7&ids%5B%5D=1&ids%5B%5D=2"
      );
    });

    it("unchecks every subcategory under the category and restores the summary", () => {
      group.checked = true;
      instance.toggleCategory({ "target": group });

      group.checked = false;
      instance.toggleCategory({ "target": group });

      expect(alpha.checked).to.eq(false);
      expect(beta.checked).to.eq(false);
      expect(panelFrame.hasAttribute("src")).to.eq(false);
      expect(panelFrame.classList.contains("hidden")).to.eq(true);
      expect(summary.classList.contains("hidden")).to.eq(false);
    });

    it("leaves subcategories that belong to another category untouched", () => {
      const other = subcategory("3", "/budgets/1/categories/3/panel", "20");
      instance.subcategoryTargets = [alpha, beta, other];

      group.checked = true;
      instance.toggleCategory({ "target": group });

      expect(other.checked).to.eq(false);
    });
  });

  describe("#edit", () => {
    const rowWithAssignment = (box) => {
      const row  = rowFor(box),
            cell = document.createElement("td"),
            link = document.createElement("a"),
            name = document.createElement("button");

      cell.setAttribute("data-controller", "inline-edit");
      link.click = sinon.fake();

      cell.appendChild(link);
      row.appendChild(name);
      row.appendChild(cell);

      return { link,
        name };
    };

    it("clicks the assignment link in the row", () => {
      const { link, name } = rowWithAssignment(alpha);

      instance.edit({ "target": name });

      expect(link.click).to.have.been.called;
    });

    it("does nothing when the clicked element has no row", () => {
      const orphan = document.createElement("button");

      expect(() => {
        instance.edit({ "target": orphan });
      }).to.not.throw();
    });

    it("does nothing when the row has no assignment link", () => {
      const name = document.createElement("button");
      rowFor(name);

      expect(() => {
        instance.edit({ "target": name });
      }).to.not.throw();
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
