# frozen_string_literal: true

require "rails_helper"

describe "accounts/transactions/_reconcile_link.html.erb" do
  subject(:html) do
    render partial: "accounts/transactions/reconcile_link",
           locals:  { account: account, budget: budget }

    rendered
  end

  let(:account) { create(:account, budget: budget) }
  let(:budget)  { create(:budget) }

  it "renders a turbo stream target wrapper" do
    expect(html).to have_css("span#reconcile_link")
  end

  context "when there are cleared transactions" do
    before do
      create(:transaction, :cleared, account: account)
    end

    it "renders a reconcile button" do
      expect(html).to have_button(I18n.t("accounts.transactions.index.reconcile"))
    end

    it "renders a confirmation dialog" do
      expect(html).to have_css("[data-turbo-confirm]")
    end
  end

  context "when there are no cleared transactions" do
    it "does not render a reconcile button" do
      expect(html).to have_no_button(I18n.t("accounts.transactions.index.reconcile"))
    end
  end
end
