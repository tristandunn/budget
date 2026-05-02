# frozen_string_literal: true

require "rails_helper"

describe "transfers/_show.html.erb" do
  subject(:html) do
    render partial: "transfers/show", locals: { transaction: transaction }

    rendered
  end

  let(:budget)      { create(:budget) }
  let(:checking)    { create(:account, budget: budget, name: "Checking") }
  let(:memo)        { "April rent transfer" }
  let(:savings)     { create(:account, budget: budget, name: "Savings") }
  let(:transaction) { budget.transactions.find_by("amount < 0") }

  before do
    CreateTransfer.call(
      accounts: { from: checking, to: savings },
      amount:   Money.from_amount(50),
      budget:   budget,
      date:     Date.new(2026, 4, 30),
      memo:     memo
    )
  end

  it "renders the absolute amount" do
    expect(html).to have_css("div", text: "$50.00")
  end

  it "renders the source account label" do
    expect(html).to have_css("dt", text: t("transfers.show.from"))
  end

  it "renders the source account name" do
    expect(html).to have_css("dd", text: "Checking")
  end

  it "renders the destination account label" do
    expect(html).to have_css("dt", text: t("transfers.show.to"))
  end

  it "renders the destination account name" do
    expect(html).to have_css("dd", text: "Savings")
  end

  it "renders the date label" do
    expect(html).to have_css("dt", text: t("transfers.show.date"))
  end

  it "renders the formatted date" do
    expect(html).to have_css("dd", text: I18n.l(Date.new(2026, 4, 30)))
  end

  it "renders the memo label" do
    expect(html).to have_css("dt", text: t("transfers.show.memo"))
  end

  it "renders the memo text" do
    expect(html).to have_css("dd", text: "April rent transfer")
  end

  it "renders no visible form fields" do
    expect(html).to have_no_css("input:not([type='hidden']), select, textarea")
  end

  it "renders a delete button" do
    expect(html).to have_button(t("transfers.show.delete.submit"))
  end

  context "when viewed from the inflow side" do
    let(:transaction) { budget.transactions.find_by("amount > 0") }

    it "still shows the source account as the originating account" do
      expect(html).to have_css("dd", text: "Checking")
    end

    it "still shows the destination account as the receiving account" do
      expect(html).to have_css("dd", text: "Savings")
    end
  end

  context "without a memo" do
    let(:memo) { nil }

    it "does not render a memo label" do
      expect(html).to have_no_css("dt", text: t("transfers.show.memo"))
    end
  end

  context "when the transaction is not destroyable" do
    before do
      transaction.transfer_pair.update!(status: :reconciled)
    end

    it "does not render a delete button" do
      expect(html).to have_no_button(t("transfers.show.delete.submit"))
    end
  end
end
