# frozen_string_literal: true

require "rails_helper"

describe "categories/_target.html+desktop.erb" do
  subject(:html) do
    render(
      locals:   {
        budget:          budget,
        category:        subcategory,
        budget_snapshot: budget_snapshot
      },
      partial:  "categories/target",
      variants: [:desktop]
    )

    rendered
  end

  let(:budget)          { subcategory.budget }
  let(:budget_snapshot) { instance_double(BudgetSnapshot, date: Date.current, snoozed?: false) }
  let(:subcategory)     { build_stubbed(:category, :subcategory) }

  before do
    stub_template("categories/_target_summary.html.erb" => "TARGET_SUMMARY_PARTIAL")
  end

  it "wraps the target in its own turbo frame" do
    expect(html).to have_css("turbo-frame##{dom_id(subcategory, :target)}")
  end

  context "with a target" do
    let(:subcategory) { build_stubbed(:category, :subcategory, :with_monthly_spending_target) }

    it "renders the target summary partial" do
      expect(html).to include("TARGET_SUMMARY_PARTIAL")
    end

    it "links the edit target button to the edit form with month and year" do
      expect(html).to have_link(
        t("categories.show.target.desktop.edit"),
        href: edit_budget_category_target_path(budget, subcategory,
                                               year:  budget_snapshot.date.year,
                                               month: budget_snapshot.date.month)
      )
    end

    it "renders a snooze button" do
      expect(html).to have_button(t("categories.show.target.desktop.snooze"))
    end

    it "posts the snooze button to the snooze path" do
      expect(html).to have_css(
        "form[action='#{budget_category_snooze_path(budget, subcategory,
                                                    year:  budget_snapshot.date.year,
                                                    month: budget_snapshot.date.month)}'][method='post']"
      )
    end

    context "when snoozed" do
      before do
        allow(budget_snapshot).to receive(:snoozed?).with(subcategory).and_return(true)
      end

      it "renders an unsnooze button" do
        expect(html).to have_button(t("categories.show.target.desktop.unsnooze"))
      end

      it "submits the unsnooze button as a DELETE to the snooze path" do
        expect(html).to have_css(
          "form[action='#{budget_category_snooze_path(budget, subcategory,
                                                      year:  budget_snapshot.date.year,
                                                      month: budget_snapshot.date.month)}'] " \
          "input[name='_method'][value='delete']",
          visible: :hidden
        )
      end
    end
  end

  context "without a target" do
    it "renders the target prompt with the category name" do
      expect(html).to have_text(t("categories.show.target.question", name: subcategory.name))
    end

    it "renders the target description" do
      expect(html).to have_text(t("categories.show.target.description"))
    end

    it "links the create target button to the edit form with month and year" do
      expect(html).to have_link(
        t("categories.show.target.desktop.create"),
        href: edit_budget_category_target_path(budget, subcategory,
                                               year:  budget_snapshot.date.year,
                                               month: budget_snapshot.date.month)
      )
    end

    it "does not render a snooze button" do
      expect(html).to have_no_button(t("categories.show.target.desktop.snooze"))
    end
  end
end
