# frozen_string_literal: true

require "rails_helper"

describe "users/show.html+desktop.erb" do
  subject(:html) do
    render template: "users/show", formats: [:html], variants: [:desktop]

    rendered
  end

  let(:user) { build_stubbed(:user) }

  before do
    assign :user, user
  end

  it "sets the page title" do
    html

    expect(view.content_for(:title)).to eq(t("users.settings"))
  end

  it "submits the form as a PATCH to the user path" do
    expect(html).to have_css(
      "form[action='#{account_path}'] input[name='_method'][value='patch']",
      visible: :hidden
    )
  end

  it "renders the e-mail field with the current e-mail" do
    expect(html).to have_field("user_email", with: user.email, type: "email")
  end

  it "limits the e-mail field to the maximum length and requires it" do
    expect(html).to have_css("input#user_email[required][maxlength='#{User::MAXIMUM_EMAIL_LENGTH}']")
  end

  it "renders the submit button" do
    expect(html).to have_button(t("users.show.submit"))
  end

  it "does not render an error message" do
    expect(html).to have_no_css("[role='alert']")
  end

  context "when the e-mail is invalid" do
    before do
      user.errors.add(:email, :invalid)
    end

    it "renders the validation error message" do
      expect(html).to have_css(
        "[role='alert']",
        text: "#{User.human_attribute_name(:email)} #{t("errors.messages.invalid")}."
      )
    end
  end
end
