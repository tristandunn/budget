# frozen_string_literal: true

require "rails_helper"

describe "accounts/edit.html.erb" do
  subject(:html) do
    render template: "accounts/edit", formats: [:html]

    rendered
  end

  let(:account) { build_stubbed(:account) }
  let(:budget)  { account.budget }
  let(:form)    { AccountForm.from(account: account) }

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
    expect(html).to have_css("h2", text: t("accounts.edit.title"))
  end

  it "renders a close button" do
    expect(html).to have_css("button[data-action='dialog#close']")
  end
end
