# frozen_string_literal: true

require "rails_helper"

describe Transaction do
  it { is_expected.to be_a(ApplicationRecord) }

  describe "associations" do
    it { is_expected.to belong_to(:budget) }
    it { is_expected.to belong_to(:category) }
  end

  describe "validations" do
    subject { create(:transaction) }

    it { is_expected.to validate_presence_of(:amount) }
    it { is_expected.to validate_numericality_of(:amount).only_integer }
  end
end
