# frozen_string_literal: true

require "rails_helper"

describe "transactions/_transaction.html+desktop.erb" do
  subject(:html) do
    render partial: "transactions/transaction", variants: [:desktop], locals: locals

    rendered
  end

  let(:locals)      { { transaction: transaction } }
  let(:transaction) { build_stubbed(:transaction, amount: -1337, date: Date.new(2026, 6, 10), memo: "Lunch") }

  before do
    stub_template("transactions/_status_indicator.html.erb" => "STATUS_INDICATOR")
  end

  it "renders the date" do
    expect(html).to have_css("td", text: "06/10/2026")
  end

  it "does not render the account name" do
    expect(html).to have_no_css("td", text: transaction.account.name)
  end

  it "renders the payee linked to its edit page" do
    expect(html).to have_link(
      transaction.payee.name,
      href: edit_budget_transaction_path(transaction.budget, transaction)
    )
  end

  it "renders the qualified category" do
    expect(html).to have_text(
      "#{transaction.subcategory.parent.name}: #{transaction.subcategory.name}"
    )
  end

  it "renders the memo" do
    expect(html).to have_text("Lunch")
  end

  it "renders the amount in the outflow column" do
    expect(html).to have_css("td:nth-last-child(3)", text: number_to_money(1337))
  end

  it "leaves the inflow column empty for an outflow" do
    expect(html).to have_no_css("td:nth-last-child(2)", text: number_to_money(1337))
  end

  it "renders the status indicator" do
    expect(html).to include("STATUS_INDICATOR")
  end

  context "when the transaction is a transfer" do
    let(:transaction) { build_stubbed(:transaction, transfer_pair_id: 1) }

    it "renders the transfer category" do
      expect(html).to have_text(t("transactions.transfer_category"))
    end
  end

  context "when the transaction has no subcategory" do
    let(:transaction) { build_stubbed(:transaction, subcategory: nil) }

    it "renders no category" do
      expect(html).to have_no_css("td:nth-child(3)", text: /\S/)
    end
  end

  context "when the transaction is an inflow" do
    let(:transaction) { build_stubbed(:transaction, amount: 1337, date: Date.new(2026, 6, 10)) }

    it "renders the amount in the inflow column" do
      expect(html).to have_css("td:nth-last-child(2)", text: number_to_money(1337))
    end

    it "leaves the outflow column empty for an inflow" do
      expect(html).to have_no_css("td:nth-last-child(3)", text: number_to_money(1337))
    end
  end

  context "when the transaction amount is zero" do
    let(:transaction) { build_stubbed(:transaction, amount: 0, date: Date.new(2026, 6, 10)) }

    it "leaves the outflow column empty" do
      expect(html).to have_no_css("td:nth-last-child(3)", text: /\S/)
    end

    it "leaves the inflow column empty" do
      expect(html).to have_no_css("td:nth-last-child(2)", text: /\S/)
    end
  end

  context "when the transaction is scheduled" do
    let(:locals) { { transaction: transaction, scheduled: true } }

    it "does not render a status indicator" do
      expect(html).to have_no_text("STATUS_INDICATOR")
    end

    it "applies the scheduled styling" do
      expect(html).to have_css("tr.bg-taupe-100")
    end

    it "does not render the recurring icon" do
      expect(html).to have_no_css("[aria-label='#{t("transactions.transaction.recurring")}']")
    end
  end

  context "when the transaction is recurring and scheduled" do
    let(:locals)      { { transaction: transaction, scheduled: true } }
    let(:transaction) { build_stubbed(:transaction, :recurring) }

    it "renders the recurring icon in the date column" do
      expect(html).to have_css(
        "td [role='img'][aria-label='#{t("transactions.transaction.recurring")}']"
      )
    end
  end

  context "when the transaction is recurring but not scheduled" do
    let(:locals)      { { transaction: transaction } }
    let(:transaction) { build_stubbed(:transaction, :recurring) }

    it "does not render the recurring icon" do
      expect(html).to have_no_css("[aria-label='#{t("transactions.transaction.recurring")}']")
    end
  end

  context "when rendered in the all-accounts context" do
    let(:locals) { { transaction: transaction, context: :transactions } }

    it "renders the account name" do
      expect(html).to have_css("td", text: transaction.account.name)
    end
  end

  context "when the transaction is reconciled" do
    let(:transaction) { build_stubbed(:transaction, :reconciled, date: Date.new(2026, 6, 10)) }

    it "does not link the payee to the edit page" do
      expect(html).to have_no_link(
        href: edit_budget_transaction_path(transaction.budget, transaction)
      )
    end
  end
end
