# frozen_string_literal: true

require "rails_helper"

describe Membership do
  it { is_expected.to be_a(ApplicationRecord) }

  describe "associations" do
    it { is_expected.to belong_to(:budget).inverse_of(:memberships) }
    it { is_expected.to belong_to(:user).inverse_of(:memberships) }
  end

  describe "validations" do
    subject { create(:membership) }

    it { is_expected.to validate_uniqueness_of(:user_id).scoped_to(:budget_id) }
  end
end
