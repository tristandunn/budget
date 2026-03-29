# frozen_string_literal: true

require "rails_helper"

describe "shared/_toolbar.html.erb" do
  subject(:html) do
    render partial: "shared/toolbar", formats: [:html], locals: { budget: budget }

    rendered
  end

  let(:budget) { create(:budget) }

  it "renders the plan link" do
    expect(html).to have_link(I18n.t("toolbar.plan"), href: budget_path(budget))
  end

  it "renders the spending link" do
    expect(html).to have_link(I18n.t("toolbar.spending"), href: budget_transactions_path(budget))
  end

  it "renders the accounts link" do
    expect(html).to have_link(I18n.t("toolbar.accounts"), href: budget_accounts_path(budget))
  end

  it "renders the reflect link" do
    expect(html).to have_link(I18n.t("toolbar.reflect"), href: root_path)
  end

  it "renders the add transaction link" do
    expect(html).to have_link(href: new_budget_transaction_path(budget))
  end

  context "when on the budgets controller" do
    before do
      allow(view).to receive(:controller_name).and_return("budgets")
    end

    it "renders the plan link as active" do
      expect(html).to have_link(I18n.t("toolbar.plan"), class: "text-slate-800")
    end

    it "renders the spending link as inactive" do
      expect(html).to have_link(I18n.t("toolbar.spending"), class: "text-slate-400")
    end

    it "renders the accounts link as inactive" do
      expect(html).to have_link(I18n.t("toolbar.accounts"), class: "text-slate-400")
    end
  end

  context "when on the transactions controller" do
    before do
      allow(view).to receive(:controller_path).and_return("transactions")
    end

    it "renders the spending link as active" do
      expect(html).to have_link(I18n.t("toolbar.spending"), class: "text-slate-800")
    end

    it "renders the plan link as inactive" do
      expect(html).to have_link(I18n.t("toolbar.plan"), class: "text-slate-400")
    end

    it "renders the accounts link as inactive" do
      expect(html).to have_link(I18n.t("toolbar.accounts"), class: "text-slate-400")
    end
  end

  context "when on the accounts controller" do
    before do
      allow(view).to receive(:controller_path).and_return("accounts")
    end

    it "renders the accounts link as active" do
      expect(html).to have_link(I18n.t("toolbar.accounts"), class: "text-slate-800")
    end

    it "renders the plan link as inactive" do
      expect(html).to have_link(I18n.t("toolbar.plan"), class: "text-slate-400")
    end

    it "renders the spending link as inactive" do
      expect(html).to have_link(I18n.t("toolbar.spending"), class: "text-slate-400")
    end
  end

  context "when on the account transactions controller" do
    before do
      allow(view).to receive(:controller_path).and_return("accounts/transactions")
    end

    it "renders the accounts link as active" do
      expect(html).to have_link(I18n.t("toolbar.accounts"), class: "text-slate-800")
    end

    it "renders the plan link as inactive" do
      expect(html).to have_link(I18n.t("toolbar.plan"), class: "text-slate-400")
    end

    it "renders the spending link as inactive" do
      expect(html).to have_link(I18n.t("toolbar.spending"), class: "text-slate-400")
    end
  end
end
