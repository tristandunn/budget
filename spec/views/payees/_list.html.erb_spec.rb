# frozen_string_literal: true

require "rails_helper"

describe "payees/_list.html.erb" do
  subject(:html) do
    render(
      locals:  { budget: budget, payees: payees },
      partial: "payees/list"
    )

    rendered
  end

  let(:budget) { build_stubbed(:budget) }

  context "with payees" do
    let(:payee)  { build_stubbed(:payee, budget: budget) }
    let(:payees) { [payee] }

    it "renders the payee as a link to the rename dialog" do
      expect(html).to have_link(payee.name, href: edit_budget_payee_path(budget, payee))
    end

    it "targets the rename dialog turbo frame" do
      expect(html).to have_css("a[data-turbo-frame='payee_rename_dialog']", text: payee.name)
    end

    it "exposes the payee name for the search filter" do
      expect(html).to have_css(
        "li[data-label='#{payee.name}'][data-payee-manager-target='item']"
      )
    end
  end

  context "without payees" do
    let(:payees) { [] }

    it "renders the empty state" do
      expect(html).to have_css("p", text: t("payees.index.empty"))
    end
  end
end
