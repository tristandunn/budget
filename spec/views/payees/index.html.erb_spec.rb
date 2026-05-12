# frozen_string_literal: true

require "rails_helper"

describe "payees/index.html.erb" do
  subject(:html) do
    render template: "payees/index", formats: [:html]

    rendered
  end

  let(:budget) { build_stubbed(:budget) }
  let(:payees) { [] }

  before do
    stub_template("payees/_list.html.erb" => "LIST_PARTIAL")

    assign :budget, budget
    assign :payees, payees
  end

  it "renders the payees dialog turbo frame" do
    expect(html).to have_css("turbo-frame#payees_dialog")
  end

  it "renders the dialog title" do
    expect(html).to have_css("h2", text: t("payees.index.title"))
  end

  it "renders a done button that closes the dialog" do
    expect(html).to have_css(
      "button[data-action='dialog#close']", text: t("payees.index.done")
    )
  end

  it "renders the search input" do
    expect(html).to have_css(
      "input[type='search'][aria-label='#{t("payees.index.search")}']"
    )
  end

  it "wires the search input to the payee-manager controller" do
    expect(html).to have_css(
      "input[data-payee-manager-target='search']" \
      "[data-action='input->payee-manager#filter search->payee-manager#filter']"
    )
  end

  it "wraps the list in the payees_list turbo frame" do
    expect(html).to have_css("turbo-frame#payees_list")
  end

  it "renders the list partial" do
    expect(html).to include("LIST_PARTIAL")
  end

  it "renders the hidden no-matches message" do
    expect(html).to have_css(
      "p.hidden[data-payee-manager-target='empty']", text: t("payees.index.no_matches")
    )
  end
end
