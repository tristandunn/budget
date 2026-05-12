# frozen_string_literal: true

require "rails_helper"

describe "payees/update.turbo_stream.erb" do
  subject(:html) do
    render template: "payees/update", formats: [:turbo_stream]

    rendered
  end

  let(:budget) { build_stubbed(:budget) }
  let(:payees) { [] }

  before do
    stub_template("payees/_list.html.erb" => "LIST_PARTIAL")

    assign :budget, budget
    assign :payees, payees
  end

  it "updates the payees list frame" do
    expect(html).to have_css("turbo-stream[action='update'][target='payees_list']")
  end

  it "renders the list partial inside the payees list stream" do
    expect(html).to include("LIST_PARTIAL")
  end

  it "updates the rename dialog frame" do
    expect(html).to have_css("turbo-stream[action='update'][target='payee_rename_dialog']")
  end

  it "renders the dismisser controller inside the rename dialog stream" do
    expect(html).to include('data-controller="dialog-dismisser"')
  end
end
