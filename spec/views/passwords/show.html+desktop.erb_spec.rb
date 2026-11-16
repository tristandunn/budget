# frozen_string_literal: true

require "rails_helper"

describe "passwords/show.html+desktop.erb" do
  subject(:html) do
    render template: "passwords/show", formats: [:html], variants: [:desktop]

    rendered
  end

  let(:form) { PasswordForm.new(user: build_stubbed(:user)) }

  before do
    assign :form, form
  end

  it "sets the page title" do
    html

    expect(view.content_for(:title)).to eq(t("users.password"))
  end

  it "submits the form as a PATCH to the password path" do
    expect(html).to have_css(
      "form[action='#{account_password_path}'] input[name='_method'][value='patch']",
      visible: :hidden
    )
  end

  it "renders the password fields" do
    expect(html).to have_field("password_form_current_password", type: "password")
      .and(have_field("password_form_password", type: "password"))
      .and(have_field("password_form_password_confirmation", type: "password"))
  end

  it "requires every password field" do
    expect(html).to have_css("input[type='password'][required]", count: 3)
  end

  it "limits the new password fields to the allowed length" do
    expect(html).to have_css(
      "input#password_form_password[minlength='#{User::MINIMUM_PASSWORD_LENGTH}']" \
      "[maxlength='#{User::MAXIMUM_PASSWORD_LENGTH}']"
    )
  end

  it "renders the submit button" do
    expect(html).to have_button(t("passwords.show.submit"))
  end

  it "does not render an error message" do
    expect(html).to have_no_css("[role='alert']")
  end

  context "when the current password is incorrect" do
    let(:label)   { PasswordForm.human_attribute_name(:current_password).humanize }
    let(:message) { t("activemodel.errors.models.password_form.attributes.current_password.incorrect") }

    before do
      form.errors.add(:current_password, :incorrect)
    end

    it "renders the validation error message" do
      expect(html).to have_css("[role='alert']", normalize_ws: true, text: "#{label} #{message}.")
    end
  end

  context "when the confirmation does not match" do
    let(:label)   { PasswordForm.human_attribute_name(:password_confirmation).humanize }
    let(:message) { t("activemodel.errors.models.password_form.attributes.password_confirmation.confirmation") }

    before do
      form.errors.add(:password_confirmation, :confirmation)
    end

    it "renders the validation error message" do
      expect(html).to have_css("[role='alert']", normalize_ws: true, text: "#{label} #{message}.")
    end
  end

  context "when the new password is invalid" do
    let(:label)   { PasswordForm.human_attribute_name(:password).humanize }
    let(:message) { t("errors.messages.too_short.other", count: User::MINIMUM_PASSWORD_LENGTH) }

    before do
      form.errors.add(:password, :too_short, count: User::MINIMUM_PASSWORD_LENGTH)
    end

    it "renders the validation error message" do
      expect(html).to have_css("[role='alert']", normalize_ws: true, text: "#{label} #{message}.")
    end
  end
end
