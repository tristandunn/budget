# frozen_string_literal: true

require "rails_helper"

describe "transactions/index.html.erb" do
  subject(:html) do
    render template: "transactions/index", formats: [:html]

    rendered
  end

  let(:budget) { create(:budget) }

  before do
    stub_template("shared/_toolbar.html.erb"    => "TOOLBAR_PARTIAL")
    stub_template("transactions/_list.html.erb" => "LIST_PARTIAL")

    assign :budget,               budget
    assign :grouped_transactions, {}
  end

  it "renders the header" do
    expect(html).to have_css("h1", text: t("transactions.index.title"))
  end

  it "renders the transaction list" do
    expect(html).to include("LIST_PARTIAL")
  end

  it "renders the toolbar" do
    expect(html).to include("TOOLBAR_PARTIAL")
  end
end
