# frozen_string_literal: true

require "rails_helper"

describe "accounts/transactions/_actions.html.erb" do
  subject(:html) do
    render partial: "accounts/transactions/actions",
           locals:  { account: account, budget: budget }

    rendered
  end

  let(:account) { create(:account, budget: budget) }
  let(:budget)  { create(:budget) }

  it "renders a popover trigger button" do
    expect(html).to have_css(
      "button[aria-label='#{I18n.t("accounts.transactions.index.actions")}']"
    )
  end

  it "renders a reconcile button" do
    expect(html).to have_button(I18n.t("accounts.transactions.index.reconcile"))
  end

  it "renders a confirmation dialog" do
    expect(html).to have_css("[data-turbo-confirm]")
  end

  context "when the account has been reconciled" do
    before do
      create(:transaction, account: account, status: :reconciled)
    end

    it "renders the last reconciled time" do
      expect(html).to have_text("Reconciled today")
    end
  end

  context "when the account has never been reconciled" do
    it "renders reconciled never" do
      expect(html).to have_text(I18n.t("accounts.transactions.index.reconciled_never"))
    end
  end
end
