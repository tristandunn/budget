# frozen_string_literal: true

require "rails_helper"

describe "transactions/_actions.html.erb" do
  subject(:html) do
    render partial: "transactions/actions",
           locals:  { budget: budget }

    rendered
  end

  let(:budget) { create(:budget) }

  before do
    stub_template("shared/transactions/_hide_reconciled.html.erb" => "HIDE_RECONCILED_PARTIAL")
  end

  it "renders a popover trigger button" do
    expect(html).to have_css(
      "button[aria-label='#{I18n.t("transactions.index.actions")}']"
    )
  end

  it "renders the hide reconciled partial" do
    expect(html).to include("HIDE_RECONCILED_PARTIAL")
  end
end
