# frozen_string_literal: true

require "rails_helper"

describe "Creating a new session" do
  let(:password) { generate(:password) }
  let(:user)     { create(:user, password: password) }

  before do
    create(:budget)

    visit new_session_path
  end

  it "successfully" do
    fill_in_and_submit(
      email:    user.email,
      password: password
    )

    expect(page).to have_button(t("budgets.show.sign_out"), visible: :all)
  end

  it "with invalid e-mail" do
    fill_in_and_submit(
      email:    "example@localhost",
      password: password
    )

    expect(page).to have_css(".field_with_errors #session_form_email")
  end

  it "with invalid password" do
    fill_in_and_submit(
      email:    user.email,
      password: "invalid"
    )

    expect(page).to have_css(".field_with_errors #session_form_email")
  end

  protected

  def fill_in_and_submit(email:, password:)
    fill_in SessionForm.human_attribute_name(:email),    with: email
    fill_in SessionForm.human_attribute_name(:password), with: password
    click_on t("sessions.new.submit")
  end
end
