# frozen_string_literal: true

require "rails_helper"

describe "shared/transactions/_hide_reconciled.html.erb" do
  subject(:html) do
    render partial: "shared/transactions/hide_reconciled",
           locals:  { budget: budget }

    rendered
  end

  let(:budget) { create(:budget) }

  context "when reconciled transactions are hidden" do
    before do
      budget.settings.update(hide_reconciled: "1")
    end

    it "renders a show reconciled button" do
      expect(html).to have_button(t("transactions.reconciled.show"))
    end
  end

  context "when reconciled transactions are visible" do
    it "renders a hide reconciled button" do
      expect(html).to have_button(t("transactions.reconciled.hide"))
    end
  end
end
