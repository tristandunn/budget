# frozen_string_literal: true

require "rails_helper"

describe Current do
  let(:budget) { build_stubbed(:budget, settings: { time_zone: "Asia/Tokyo" }) }

  it { is_expected.to be_a(ActiveSupport::CurrentAttributes) }

  describe ".reset" do
    before do
      described_class.budget = budget
    end

    it "restores the default time zone" do
      described_class.reset

      expect(Time.zone.name).to eq(Rails.configuration.time_zone)
    end
  end

  describe "#budget=" do
    before do
      described_class.budget = budget
    end

    it "changes the time zone to the budget's time zone" do
      expect(Time.zone.name).to eq("Asia/Tokyo")
    end

    it "restores the default time zone when assigned nil" do
      described_class.budget = nil

      expect(Time.zone.name).to eq(Rails.configuration.time_zone)
    end
  end
end
