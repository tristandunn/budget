# frozen_string_literal: true

require "rails_helper"

describe "transactions/summaries/show.html.erb" do
  subject(:html) do
    render template: "transactions/summaries/show", formats: [:html]

    rendered
  end

  let(:summary) { instance_double(TransactionSummary, size: 2, total: 1_500) }

  before do
    assign :summary, summary
  end

  it "renders the summary inside the transaction selection frame" do
    expect(html).to have_css("turbo-frame#transaction_selection")
  end

  it "renders the total for the selection" do
    expect(html).to have_css("turbo-frame p", text: number_to_money(1_500))
  end

  it "renders the number of selected transactions" do
    expect(html).to have_css(
      "turbo-frame p",
      text: t("transactions.summaries.show.selected_total", number: 2)
    )
  end
end
