# frozen_string_literal: true

require "rails_helper"

describe Category do
  it { is_expected.to be_a(ApplicationRecord) }

  describe "associations" do
    it { is_expected.to belong_to(:budget) }
    it { is_expected.to belong_to(:parent).class_name("Category").optional(true) }

    it { is_expected.to have_many(:subcategories).class_name("Category").inverse_of(:parent).dependent(:destroy) }
  end

  describe "validations" do
    subject { create(:category) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).scoped_to(:budget_id).case_insensitive }

    it { is_expected.to validate_numericality_of(:position).only_integer }
  end
end
