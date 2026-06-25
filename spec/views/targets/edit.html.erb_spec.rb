# frozen_string_literal: true

require "rails_helper"

describe "targets/edit.html.erb" do
  subject(:html) do
    render template: "targets/edit", formats: [:html]

    rendered
  end

  let(:budget)          { subcategory.budget }
  let(:budget_snapshot) { BudgetSnapshot.new(budget) }
  let(:form)            { TargetForm.from(category: subcategory) }
  let(:subcategory)     { build_stubbed(:category, :subcategory) }

  before do
    assign :budget, budget
    assign :budget_snapshot, budget_snapshot
    assign :category, subcategory
    assign :form, form
  end

  it "renders the target dialog turbo frame" do
    expect(html).to have_css("turbo-frame#category_target_dialog")
  end

  it "renders the target amount field" do
    expect(html).to have_field("target_form_target_amount_input")
  end

  it "wires the positive amount controller to the target amount field" do
    expect(html).to have_css(
      "input#target_form_target_amount_input" \
      "[data-controller='amount'][data-amount-positive-value='true']"
    )
  end

  it "renders the refill target type option" do
    expect(html).to have_field("target_form_target_type_monthly_spending", type: :radio, visible: :all)
  end

  it "renders the set-aside target type option" do
    expect(html).to have_field("target_form_target_type_monthly_savings", type: :radio, visible: :all)
  end

  it "selects the refill option by default" do
    expect(html).to have_checked_field("target_form_target_type_monthly_spending", visible: :all)
  end

  context "when the category has a monthly savings target" do
    let(:subcategory) { build_stubbed(:category, :subcategory, :with_monthly_savings_target) }

    it "selects the set-aside option" do
      expect(html).to have_checked_field("target_form_target_type_monthly_savings", visible: :all)
    end
  end

  it "renders a submit button targeting the target form" do
    expect(html).to have_css(
      "button[type='submit'][form='target_form']",
      text: t("targets.edit.submit")
    )
  end

  it "renders a cancel button that closes the dialog" do
    expect(html).to have_css(
      "button[data-action='dialog#close']", text: t("targets.edit.cancel")
    )
  end

  context "when the category has no target" do
    it "renders the create title" do
      expect(html).to have_css("h2", text: t("targets.edit.create_title"))
    end

    it "does not render the delete button" do
      expect(html).to have_no_button(t("targets.edit.delete"))
    end
  end

  context "when the category has a target" do
    let(:subcategory) { build_stubbed(:category, :subcategory, :with_monthly_spending_target) }

    it "renders the edit title" do
      expect(html).to have_css("h2", text: t("targets.edit.edit_title"))
    end

    it "renders the delete button" do
      expect(html).to have_button(t("targets.edit.delete"))
    end

    it "submits the delete button to the target path" do
      path = budget_category_target_path(budget, subcategory,
                                         year:  budget_snapshot.date.year,
                                         month: budget_snapshot.date.month)

      expect(html).to have_css("form[action='#{path}'][method='post']")
    end
  end

  context "with a budget snapshot for a non-current month" do
    let(:budget_snapshot) { instance_double(BudgetSnapshot, date: Date.new(2025, 8, 1)) }

    it "submits the form preserving the snapshot's month and year" do
      expect(html).to have_css(
        "form[action='#{budget_category_target_path(budget, subcategory, year: 2025, month: 8)}']"
      )
    end
  end
end
