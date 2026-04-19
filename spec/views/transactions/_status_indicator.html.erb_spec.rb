# frozen_string_literal: true

require "rails_helper"

describe "transactions/_status_indicator.html.erb" do
  subject(:html) do
    render partial: "transactions/status_indicator", locals: { transaction: transaction }

    rendered
  end

  let(:budget) { build_stubbed(:budget) }

  context "when the transaction is pending" do
    let(:transaction) { build_stubbed(:transaction, budget: budget) }

    it "renders a clear button" do
      expect(html).to have_button("Pending")
    end

    it "uses a patch method to clear" do
      expect(html).to have_css("input[name='_method'][value='patch']", visible: :hidden)
    end

    it "does not render a reconciled indicator" do
      expect(html).to have_no_css("[aria-label='Reconciled']")
    end
  end

  context "when the transaction is cleared" do
    let(:transaction) { build_stubbed(:transaction, :cleared, budget: budget) }

    it "renders an unclear button" do
      expect(html).to have_button("Cleared")
    end

    it "uses a delete method to unclear" do
      expect(html).to have_css("input[name='_method'][value='delete']", visible: :hidden)
    end

    it "does not render a reconciled indicator" do
      expect(html).to have_no_css("[aria-label='Reconciled']")
    end
  end

  context "when the transaction is scheduled" do
    let(:transaction) { build_stubbed(:transaction, budget: budget, date: 1.week.from_now) }

    it "renders an upcoming indicator" do
      expect(html).to have_css("[aria-label='Upcoming']")
    end

    it "does not render a button" do
      expect(html).to have_no_button
    end
  end

  context "when the transaction is recurring and scheduled" do
    let(:transaction) { build_stubbed(:transaction, :recurring, budget: budget) }

    it "renders an upcoming indicator" do
      expect(html).to have_css("[aria-label='Upcoming']")
    end

    it "does not render a button" do
      expect(html).to have_no_button
    end
  end

  context "when the transaction is reconciled" do
    let(:transaction) { build_stubbed(:transaction, :reconciled, budget: budget) }

    it "renders a reconciled indicator" do
      expect(html).to have_css("[aria-label='Reconciled']")
    end

    it "does not render a button" do
      expect(html).to have_no_button
    end
  end
end
