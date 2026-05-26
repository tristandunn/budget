# frozen_string_literal: true

require "rails_helper"

describe "Merging a payee" do
  let(:budget)        { create(:budget) }
  let!(:source_payee) { create(:payee, budget: budget) }
  let!(:target_payee) { create(:payee, budget: budget) }

  before do
    sign_in_for(budget)
    visit budget_payees_path(budget)
    click_on source_payee.name
    fill_in "payee_form_name", with: target_payee.name
    click_on t("payees.edit.submit")
  end

  it "removes the renamed payee from the list" do
    expect(page).to have_text(target_payee.name).and(have_no_text(source_payee.name))
  end
end
