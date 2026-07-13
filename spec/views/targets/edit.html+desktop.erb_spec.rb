# frozen_string_literal: true

require "rails_helper"

describe "targets/edit.html+desktop.erb" do
  subject(:html) do
    render template: "targets/edit", formats: [:html], variants: [:desktop]

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

    stub_template("targets/_amount_field.html.erb" => "AMOUNT_FIELD_PARTIAL")
  end

  it "renders the target turbo frame" do
    expect(html).to have_css("turbo-frame##{dom_id(subcategory, :target)}")
  end

  it "dismisses the inline edit on the escape key" do
    expect(html).to have_css(
      "[data-controller='edit-dismisser'][data-action='keydown.esc->edit-dismisser#cancel']"
    )
  end

  it "renders the amount field partial" do
    expect(html).to include("AMOUNT_FIELD_PARTIAL")
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

  it "renders the inline submit button" do
    expect(html).to have_button(t("targets.edit.submit"))
  end

  it "renders a cancel link back to the category" do
    expect(html).to have_link(
      t("targets.edit.cancel"),
      href: budget_category_path(budget, subcategory,
                                 year:  budget_snapshot.date.year,
                                 month: budget_snapshot.date.month)
    )
  end

  it "targets the cancel link for dismissal" do
    expect(html).to have_css(
      "a[data-edit-dismisser-target='cancel']", text: t("targets.edit.cancel")
    )
  end

  context "when the category has a monthly savings target" do
    let(:subcategory) { build_stubbed(:category, :subcategory, :with_monthly_savings_target) }

    it "selects the set-aside option" do
      expect(html).to have_checked_field("target_form_target_type_monthly_savings", visible: :all)
    end
  end

  context "when the category has a target" do
    let(:subcategory) { build_stubbed(:category, :subcategory, :with_monthly_spending_target) }

    it "renders the delete button" do
      expect(html).to have_button(t("targets.edit.desktop.delete"))
    end

    it "submits the delete button as a DELETE to the target path" do
      path = budget_category_target_path(budget, subcategory,
                                         year:  budget_snapshot.date.year,
                                         month: budget_snapshot.date.month)

      expect(html).to have_css(
        "form[action='#{path}'][method='post'] input[name='_method'][value='delete']",
        visible: :hidden
      )
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

  context "when the category has no target" do
    it "does not render the delete button" do
      expect(html).to have_no_button(t("targets.edit.desktop.delete"))
    end
  end
end
