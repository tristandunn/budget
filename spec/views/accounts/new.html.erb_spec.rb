# frozen_string_literal: true

require "rails_helper"

describe "accounts/new.html.erb" do
  subject(:html) do
    render template: "accounts/new", formats: [:html]

    rendered
  end

  let(:budget) { build_stubbed(:budget) }
  let(:form)   { AccountForm.new(budget: budget) }

  before do
    stub_template("accounts/_form.html.erb" => "FORM_PARTIAL")

    assign :budget, budget
    assign :form,   form
  end

  it "renders the form partial" do
    expect(html).to include("FORM_PARTIAL")
  end

  it "wraps the content in the account dialog turbo frame" do
    expect(html).to have_css("turbo-frame#account_dialog", visible: :all)
  end

  it "renders the dialog title" do
    expect(html).to have_css("h2", text: t("accounts.new.title"))
  end

  it "renders a close button" do
    expect(html).to have_css("button[data-action='dialog#close']")
  end
end
