# frozen_string_literal: true

require "rails_helper"

describe "shared/_sidebar.html.erb" do
  subject(:html) do
    render partial: "shared/sidebar", locals: { budget: budget, account_id: account_id }

    rendered
  end

  let(:account_id)         { nil }
  let(:budget)             { create(:budget, user: user) }
  let!(:cash_account)      { create(:account, budget: budget, balance: 10_000) }
  let!(:credit_account)    { create(:account, :credit, budget: budget, balance: -5_000) }
  let(:user)               { create(:user, email: "person@example.com") }

  before do
    Current.user = user

    view.extend(SidebarHelper)

    without_partial_double_verification do
      allow(view).to receive(:signed_in?).and_return(true)
    end
  end

  it "renders the application title" do
    expect(html).to have_text(t("title"))
  end

  it "renders the current user email" do
    expect(html).to have_text("person@example.com")
  end

  it "renders the transaction dialog labelled by its title" do
    expect(html).to have_css(
      "dialog#transaction_dialog_modal[aria-labelledby='transaction_dialog_title'] " \
      "turbo-frame#transaction_dialog",
      visible: :all
    )
  end

  it "renders the payees dialog" do
    expect(html).to have_css(
      "dialog#payees_dialog_modal turbo-frame#payees_dialog", visible: :all
    )
  end

  it "renders the payee rename dialog" do
    expect(html).to have_css(
      "dialog#payee_rename_dialog_modal turbo-frame#payee_rename_dialog", visible: :all
    )
  end

  it "renders the add transaction link" do
    expect(html).to have_css(
      "a#add-transaction[href='#{new_budget_transaction_path(budget)}']" \
      "[aria-label='#{t("toolbar.add_transaction")}']"
    )
  end

  it "renders the manage payees link" do
    expect(html).to have_link(
      t("budgets.show.manage_payees"),
      href: budget_payees_path(budget)
    )
  end

  it "targets the payees dialog frame from the manage payees link" do
    expect(html).to have_css(
      "a#manage-payees[data-turbo-frame='payees_dialog']",
      text: t("budgets.show.manage_payees")
    )
  end

  it "links to the budget plan" do
    expect(html).to have_link(t("toolbar.plan"), href: budget_path(budget))
  end

  it "links to all accounts" do
    expect(html).to have_link(t("sidebar.all_accounts"), href: budget_transactions_path(budget))
  end

  it "links to reflect" do
    expect(html).to have_link(t("toolbar.reflect"), href: root_path)
  end

  it "renders the cash and credit group labels" do
    expect(html).to have_text(t("accounts.index.cash"))
      .and(have_text(t("accounts.index.credit")))
  end

  it "lists each account with a link to its register" do
    expect(html).to have_link(
      cash_account.name, href: budget_account_transactions_path(budget, cash_account)
    ).and(
      have_link(credit_account.name, href: budget_account_transactions_path(budget, credit_account))
    )
  end

  it "renders the account balances" do
    expect(html).to have_text(number_to_money(cash_account.balance))
      .and(have_text(number_to_money(credit_account.balance)))
  end

  it "renders a sign out form when signed in" do
    expect(html).to have_css(
      "form[action='#{session_path}'] input[name='_method'][value='delete']",
      visible: :all
    ).and(have_button(t("budgets.show.sign_out")))
  end

  context "when an account is provided" do
    let(:account_id) { cash_account.id }

    it "defaults the account on the add transaction link" do
      expect(html).to have_css(
        "a#add-transaction[href='#{new_budget_transaction_path(budget, account_id: cash_account.id)}']"
      )
    end
  end

  context "when signed out" do
    before do
      without_partial_double_verification do
        allow(view).to receive(:signed_in?).and_return(false)
      end
    end

    it "does not render a sign out form" do
      expect(html).to have_no_button(t("budgets.show.sign_out"))
    end
  end
end
