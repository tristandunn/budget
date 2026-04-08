# frozen_string_literal: true

require "rails_helper"

describe Payee do
  it { is_expected.to be_a(ApplicationRecord) }

  describe "associations" do
    it { is_expected.to belong_to(:budget) }
    it { is_expected.to have_many(:transactions).dependent(:restrict_with_error) }
  end

  describe "validations" do
    subject(:payee) { create(:payee) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).scoped_to(:budget_id) }
  end
end
