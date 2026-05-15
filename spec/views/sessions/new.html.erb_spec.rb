# frozen_string_literal: true

require "rails_helper"

describe "sessions/new.html.erb" do
  subject(:html) do
    render template: "sessions/new"

    rendered
  end

  let(:form) { build(:session_form) }

  before do
    assign :form, form
  end

  it "renders the title" do
    expect(html).to have_css("h1", text: t("sessions.new.title"))
  end

  it "renders a form to create a session" do
    expect(html).to have_css(%(form[action="#{session_path}"][method="post"]))
  end

  it "renders an e-mail field" do
    expect(html).to have_css(
      %(input#session_form_email[autocomplete="email"][autofocus][required])
    )
  end

  it "renders a password field" do
    expect(html).to have_css(
      %(input#session_form_password[autocomplete="current-password"][required])
    )
  end

  it "renders a submit button" do
    expect(html).to have_button(t("sessions.new.submit"))
  end

  context "with errors" do
    before do
      form.errors.add(:email, :unknown)
    end

    it "wraps the e-mail field in error container" do
      expect(html).to have_css(".field_with_errors #session_form_email")
    end
  end
end
