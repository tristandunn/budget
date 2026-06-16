# frozen_string_literal: true

require "rails_helper"

describe "Accounts", :mobile do
  context "with a budget" do
    let(:budget) { create(:budget) }

    before do
      sign_in_for(budget)
    end

    it "renders the page title" do
      visit budget_accounts_path(budget)

      expect(page).to have_text(t("accounts.index.title"))
    end

    context "with a cash account", :js do
      let(:account) { create(:account, budget: budget) }

      before do
        visit budget_accounts_path(account.budget)
      end

      it "renders the account" do
        expect(page).to have_text(account.name)
      end

      it "hides accounts when clicking the header" do
        find("h2", text: t("accounts.index.cash")).click

        expect(page).to have_no_text(account.name)
      end

      it "shows accounts when clicking a collapsed header" do
        2.times { find("h2", text: t("accounts.index.cash")).click }

        expect(page).to have_text(account.name)
      end
    end

    context "with a credit account", :js do
      let(:account) { create(:account, :credit, budget: budget) }

      before do
        visit budget_accounts_path(account.budget)
      end

      it "renders the account" do
        expect(page).to have_text(account.name)
      end

      it "hides accounts when clicking the header" do
        find("h2", text: t("accounts.index.credit")).click

        expect(page).to have_no_text(account.name)
      end

      it "shows accounts when clicking a collapsed header" do
        2.times { find("h2", text: t("accounts.index.credit")).click }

        expect(page).to have_text(account.name)
      end
    end
  end
end
