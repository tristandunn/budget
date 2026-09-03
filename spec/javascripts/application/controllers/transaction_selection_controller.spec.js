import TransactionSelectionController from "@app/controllers/transaction_selection_controller.js";

describe("TransactionSelectionController", () => {
  let all, alpha, beta, element, instance, total;

  const SUMMARY_URL = "/budgets/1/transactions/summary";

  const selectAll = () => {
    const box = document.createElement("input");
    box.type = "checkbox";
    box.setAttribute("data-transaction-selection-target", "all");

    return box;
  };

  const transaction = (id) => {
    const box = document.createElement("input");
    box.type = "checkbox";
    box.value = id;
    box.setAttribute("data-transaction-selection-target", "transaction");

    return box;
  };

  const rowFor = (box) => {
    const row = document.createElement("tr");
    row.appendChild(box);

    return row;
  };

  const collapsedGroup = () => {
    const group   = document.createElement("tbody"),
          content = document.createElement("tbody");

    group.classList.add("collapsed");
    group.setAttribute("data-collapsible-id-value", "scheduled");

    element.appendChild(group);
    element.appendChild(content);

    return content;
  };

  beforeEach(() => {
    all   = selectAll();
    alpha = transaction("1");
    beta  = transaction("2");

    total = document.createElement("turbo-frame");
    total.setAttribute("hidden", "");

    element = document.createElement("div");
    document.body.appendChild(element);

    instance = new TransactionSelectionController({ "scope": { element } });
    instance.allTarget          = all;
    instance.hasAllTarget       = true;
    instance.totalTarget        = total;
    instance.transactionTargets = [alpha, beta];
    instance.summaryUrlValue    = SUMMARY_URL;
    instance.connect();
  });

  afterEach(() => {
    instance.disconnect();
    element.remove();
  });

  describe("#connect", () => {
    it("discards a selection restored from a cached snapshot", () => {
      const row = rowFor(alpha);

      instance.disconnect();

      row.setAttribute("data-selected", "");
      total.removeAttribute("hidden");
      total.setAttribute("src", `${SUMMARY_URL}?ids%5B%5D=1`);
      total.appendChild(document.createElement("p"));

      instance.connect();

      expect(row.hasAttribute("data-selected")).to.eq(false);
      expect(total.hasAttribute("hidden")).to.eq(true);
      expect(total.hasAttribute("src")).to.eq(false);
      expect(total.children.length).to.eq(0);
    });
  });

  describe("#disconnect", () => {
    it("stops clearing the selection on escape", () => {
      alpha.checked = true;
      instance.toggle();

      instance.disconnect();

      document.dispatchEvent(new window.KeyboardEvent("keydown", { "key": "Escape" }));

      expect(alpha.checked).to.eq(true);
    });
  });

  describe("#toggle", () => {
    it("reveals the total when a transaction is checked", () => {
      alpha.checked = true;

      instance.toggle();

      expect(total.hasAttribute("hidden")).to.eq(false);
    });

    it("loads the summary for a single selection", () => {
      alpha.checked = true;

      instance.toggle();

      expect(total.getAttribute("src")).to.eq(`${SUMMARY_URL}?ids%5B%5D=1`);
    });

    it("loads the summary for every selected transaction", () => {
      alpha.checked = true;
      beta.checked  = true;

      instance.toggle();

      expect(total.getAttribute("src")).to.eq(`${SUMMARY_URL}?ids%5B%5D=1&ids%5B%5D=2`);
    });

    it("includes a checked row from a collapsed group", () => {
      const content = collapsedGroup();

      content.appendChild(rowFor(beta));
      beta.checked = true;

      instance.toggle();

      expect(total.getAttribute("src")).to.eq(`${SUMMARY_URL}?ids%5B%5D=2`);
    });

    it("marks every selected transaction's row", () => {
      const alphaRow = rowFor(alpha),
            betaRow  = rowFor(beta);

      alpha.checked = true;
      beta.checked  = true;

      instance.toggle();

      expect(alphaRow.hasAttribute("data-selected")).to.eq(true);
      expect(betaRow.hasAttribute("data-selected")).to.eq(true);
    });

    it("clears the row highlight when the selection is removed", () => {
      const alphaRow = rowFor(alpha);

      alpha.checked = true;
      instance.toggle();

      alpha.checked = false;
      instance.toggle();

      expect(alphaRow.hasAttribute("data-selected")).to.eq(false);
    });

    it("hides and empties the total when the last transaction is unchecked", () => {
      alpha.checked = true;
      instance.toggle();
      total.appendChild(document.createElement("p"));

      alpha.checked = false;
      instance.toggle();

      expect(total.hasAttribute("hidden")).to.eq(true);
      expect(total.hasAttribute("src")).to.eq(false);
      expect(total.children.length).to.eq(0);
    });

    it("marks the select all checkbox indeterminate for a partial selection", () => {
      alpha.checked = true;

      instance.toggle();

      expect(all.checked).to.eq(false);
      expect(all.indeterminate).to.eq(true);
    });

    it("checks the select all checkbox when every transaction is checked", () => {
      alpha.checked = true;
      beta.checked  = true;

      instance.toggle();

      expect(all.checked).to.eq(true);
      expect(all.indeterminate).to.eq(false);
    });

    it("checks the select all checkbox when every visible transaction is checked", () => {
      const content = collapsedGroup();

      content.appendChild(rowFor(beta));
      alpha.checked = true;

      instance.toggle();

      expect(all.checked).to.eq(true);
      expect(all.indeterminate).to.eq(false);
    });

    it("clears the select all checkbox when nothing is checked", () => {
      instance.toggle();

      expect(all.checked).to.eq(false);
      expect(all.indeterminate).to.eq(false);
    });

    it("leaves the select all checkbox unchecked when there are no transactions", () => {
      instance.transactionTargets = [];

      instance.toggle();

      expect(all.checked).to.eq(false);
    });

    it("does not require a select all checkbox", () => {
      instance.hasAllTarget = false;
      alpha.checked         = true;

      instance.toggle();

      expect(total.hasAttribute("hidden")).to.eq(false);
    });
  });

  describe("#toggleAll", () => {
    it("checks every transaction and shows the total", () => {
      all.checked = true;

      instance.toggleAll({ "target": all });

      expect(alpha.checked).to.eq(true);
      expect(beta.checked).to.eq(true);
      expect(total.getAttribute("src")).to.eq(`${SUMMARY_URL}?ids%5B%5D=1&ids%5B%5D=2`);
    });

    it("unchecks every transaction and hides the total", () => {
      all.checked = true;
      instance.toggleAll({ "target": all });

      all.checked = false;
      instance.toggleAll({ "target": all });

      expect(alpha.checked).to.eq(false);
      expect(beta.checked).to.eq(false);
      expect(total.hasAttribute("hidden")).to.eq(true);
    });

    it("leaves rows in a collapsed group alone", () => {
      const content = collapsedGroup();

      content.appendChild(rowFor(beta));

      all.checked = true;

      instance.toggleAll({ "target": all });

      expect(alpha.checked).to.eq(true);
      expect(beta.checked).to.eq(false);
    });
  });

  describe("escape", () => {
    const pressEscape = () => {
      document.dispatchEvent(new window.KeyboardEvent("keydown", { "key": "Escape" }));
    };

    it("clears the selection and hides the total", () => {
      alpha.checked = true;
      instance.toggle();

      pressEscape();

      expect(alpha.checked).to.eq(false);
      expect(total.hasAttribute("hidden")).to.eq(true);
    });

    it("clears a checked row in a collapsed group", () => {
      const content = collapsedGroup();

      content.appendChild(rowFor(beta));
      beta.checked = true;
      instance.toggle();

      pressEscape();

      expect(beta.checked).to.eq(false);
    });

    it("ignores other keys", () => {
      alpha.checked = true;
      instance.toggle();

      document.dispatchEvent(new window.KeyboardEvent("keydown", { "key": "Enter" }));

      expect(alpha.checked).to.eq(true);
    });

    it("does nothing when nothing is selected", () => {
      pressEscape();

      expect(total.hasAttribute("hidden")).to.eq(true);
    });

    it("does nothing while a dialog is open", () => {
      const dialog = document.createElement("dialog");
      dialog.setAttribute("open", "");
      document.body.appendChild(dialog);

      alpha.checked = true;
      instance.toggle();

      pressEscape();

      dialog.remove();

      expect(alpha.checked).to.eq(true);
    });
  });
});
