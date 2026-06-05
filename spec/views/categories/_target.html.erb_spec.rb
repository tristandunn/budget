# frozen_string_literal: true

require "rails_helper"

describe "categories/_target.html.erb" do
  subject(:html) do
    render(
      locals:  {
        budget:          budget,
        category:        subcategory,
        budget_snapshot: budget_snapshot
      },
      partial: "categories/target"
    )

    rendered
  end

  let(:budget)      { subcategory.budget }
  let(:snapshot)    { CategorySnapshot.new(amount_assigned: 40_000, amount_used: 10_000) }
  let(:subcategory) { build_stubbed(:category, :subcategory) }

  let(:budget_snapshot) do
    instance_double(BudgetSnapshot,
                    snapshot_for: snapshot,
                    date:         Date.current,
                    snoozed?:     false)
  end

  context "without a target" do
    it "renders the target prompt with the category name" do
      expect(html).to have_text(t("categories.show.target.question", name: subcategory.name))
    end

    it "links the create target button to the edit form with month and year" do
      expect(html).to have_link(
        t("categories.show.target.create"),
        href: edit_budget_category_target_path(budget, subcategory,
                                               year:  budget_snapshot.date.year,
                                               month: budget_snapshot.date.month)
      )
    end

    it "targets the target dialog frame from the create link" do
      expect(html).to have_css("a[data-turbo-frame='category_target_dialog']",
                               text: t("categories.show.target.create"))
    end

    it "does not render a snooze button" do
      expect(html).to have_no_button(t("categories.show.target.snooze"))
    end
  end

  context "with a target" do
    let(:snapshot)    { CategorySnapshot.new(amount_assigned: 150_00, amount_used: 0) }
    let(:subcategory) { build_stubbed(:category, :subcategory, :with_monthly_spending_target) }

    before do
      allow(budget_snapshot).to receive(:target_progress_for)
        .with(subcategory)
        .and_return(TargetProgress.new(category: subcategory, rollover: 0, snapshot: snapshot))
    end

    it "renders the refill type chip" do
      expect(html).to have_css("span", text: t("categories.show.target.monthly_spending_label"))
    end

    it "renders the needed amount" do
      expect(html).to have_css("div",
                               normalize_ws: true,
                               text:         "#{t("categories.show.target.needed")} $200.00")
    end

    it "renders the funded amount from the snapshot" do
      expect(html).to have_css("div",
                               normalize_ws: true,
                               text:         "#{t("categories.show.target.funded")} $150.00")
    end

    it "renders the to-go amount" do
      expect(html).to have_css("div",
                               normalize_ws: true,
                               text:         "#{t("categories.show.target.to_go")} $50.00")
    end

    it "renders the funded percentage when underfunded" do
      expect(html).to have_css("svg text", text: "75%")
    end

    it "links the edit target button to the edit form with month and year" do
      expect(html).to have_link(
        t("categories.show.target.edit"),
        href: edit_budget_category_target_path(budget, subcategory,
                                               year:  budget_snapshot.date.year,
                                               month: budget_snapshot.date.month)
      )
    end

    it "renders a snooze button" do
      expect(html).to have_button(t("categories.show.target.snooze"))
    end

    it "posts the snooze button to the snoozes path" do
      expect(html).to have_css(
        "form[action='#{budget_category_snooze_path(budget, subcategory,
                                                    year:  budget_snapshot.date.year,
                                                    month: budget_snapshot.date.month)}'][method='post']"
      )
    end

    it "does not dim the progress ring when not snoozed" do
      expect(html).to have_no_css("div.opacity-50")
    end

    context "when fully funded" do
      let(:snapshot) { CategorySnapshot.new(amount_assigned: 200_00, amount_used: 0) }

      it "renders a checkmark instead of the percentage" do
        expect(html).to have_no_css("svg text")
      end
    end

    context "with a monthly savings target" do
      let(:subcategory) { build_stubbed(:category, :subcategory, :with_monthly_savings_target) }

      it "renders the set-aside type chip" do
        expect(html).to have_css("span", text: t("categories.show.target.monthly_savings_label"))
      end
    end

    context "when snoozed" do
      before do
        allow(budget_snapshot).to receive(:snoozed?).with(subcategory).and_return(true)
      end

      it "renders an unsnooze button" do
        expect(html).to have_button(t("categories.show.target.unsnooze"))
      end

      it "submits the unsnooze button as a DELETE to the snoozes path" do
        expect(html).to have_css(
          "form[action='#{budget_category_snooze_path(budget, subcategory,
                                                      year:  budget_snapshot.date.year,
                                                      month: budget_snapshot.date.month)}'] " \
          "input[name='_method'][value='delete']",
          visible: :hidden
        )
      end

      it "dims the progress ring" do
        expect(html).to have_css("div.opacity-50")
      end
    end
  end
end
