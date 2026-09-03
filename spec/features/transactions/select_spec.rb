# frozen_string_literal: true

require "rails_helper"

describe "Transaction selection", :js do
  let(:account) { create(:account) }
  let(:budget)  { account.budget }

  let(:outflow) do
    create(:transaction, budget: budget, account: account, amount: -1_000)
  end

  let(:inflow) do
    create(:transaction, budget: budget, account: account, amount: 2_500)
  end

  let(:scheduled) do
    create(:transaction, :recurring, budget: budget, account: account, amount: -500)
  end

  before do
    [outflow, inflow, scheduled].each do |transaction|
      CreateTransaction.call(transaction: transaction)
    end

    sign_in_for(budget)

    visit budget_account_transactions_path(budget, account)
  end

  # Return the text the selection frame renders for an amount and count.
  #
  # @param amount [String] The formatted total.
  # @param count [Integer] The number of selected transactions.
  # @return [String] The expected frame text.
  def selected_total(amount, count)
    "#{amount}\n#{t("transactions.summaries.show.selected_total", number: count)}"
  end

  it "hides the selected total until a transaction is checked" do
    expect(page).to have_no_css("#transaction_selection")
  end

  it "shows the total and count for a single transaction" do
    check "select_transaction_#{outflow.id}"

    expect(page).to have_css("#transaction_selection", exact_text: selected_total("-$10.00", 1))
  end

  it "sums multiple selected transactions" do
    check "select_transaction_#{outflow.id}"

    wait_for(have_css("#transaction_selection")) do
      check "select_transaction_#{inflow.id}"
    end

    expect(page).to have_css("#transaction_selection", exact_text: selected_total("$15.00", 2))
  end

  it "highlights the selected rows" do
    check "select_transaction_#{outflow.id}"

    wait_for(have_css("tr[data-selected]", count: 1)) do
      check "select_transaction_#{inflow.id}"
    end

    expect(page).to have_css("tr[data-selected]", count: 2)
  end

  it "includes a selected scheduled transaction in the total" do
    check "select_transaction_#{scheduled.id}"

    expect(page).to have_css("#transaction_selection", exact_text: selected_total("-$5.00", 1))
  end

  it "keeps a selected scheduled transaction in the total once collapsed" do
    check "select_transaction_#{scheduled.id}"

    wait_for(have_css("#transaction_selection")) do
      find("th[scope='rowgroup']", text: t("transactions.list.scheduled")).click
    end

    expect(page).to have_no_text(scheduled.payee.name)
      .and(have_css("#transaction_selection", exact_text: selected_total("-$5.00", 1)))
  end

  it "selects every transaction from the header checkbox" do
    check "select_all"

    expect(page).to have_css("#transaction_selection", exact_text: selected_total("$10.00", 3))
  end

  it "leaves a collapsed scheduled transaction out of the header checkbox" do
    find("th[scope='rowgroup']", text: t("transactions.list.scheduled")).click

    wait_for(have_no_text(scheduled.payee.name)) do
      check "select_all"
    end

    expect(page).to have_css("#transaction_selection", exact_text: selected_total("$15.00", 2))
  end

  it "clears the selection when escape is pressed" do
    check "select_transaction_#{outflow.id}"

    wait_for(have_css("tr[data-selected]")) do
      find("body").send_keys(:escape)
    end

    expect(page).to have_no_css("tr[data-selected]")
      .and(have_no_css("#transaction_selection"))
  end

  it "keeps the selection after clearing a transaction" do
    check "select_transaction_#{outflow.id}"

    wait_for(have_css("tr[data-selected]")) do
      within "#row_transaction_#{outflow.id}" do
        click_button t("transactions.status_indicator.pending")
      end
    end

    expect(page).to have_css("tr[data-selected]", count: 1)
      .and(have_css("#transaction_selection", exact_text: selected_total("-$10.00", 1)))
  end
end
