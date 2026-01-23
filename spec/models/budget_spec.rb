# frozen_string_literal: true

require "rails_helper"

describe Budget do
  it { is_expected.to be_a(ApplicationRecord) }

  describe "associations" do
    it { is_expected.to have_many(:categories).conditions(parent_id: nil).inverse_of(:budget).dependent(:destroy) }
    it { is_expected.to have_many(:category_snapshots).dependent(:destroy) }
  end
end
