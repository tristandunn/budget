# frozen_string_literal: true

require "rails_helper"

describe Settings do
  subject(:settings) { described_class.new(budget) }

  let(:budget) { create(:budget) }

  describe "#hide_reconciled?" do
    it "returns true when enabled" do
      budget.settings = { hide_reconciled: true }

      expect(settings.hide_reconciled?).to be(true)
    end

    it "returns false when not enabled" do
      expect(settings.hide_reconciled?).to be(false)
    end
  end

  describe "#update" do
    it "enables a boolean setting" do
      settings.update(hide_reconciled: "1")

      expect(settings).to be_hide_reconciled
    end

    it "disables a boolean setting" do
      settings.update(hide_reconciled: "1")
      settings.update(hide_reconciled: "0")

      expect(settings).not_to be_hide_reconciled
    end

    it "removes the key from the store when disabling" do
      settings.update(hide_reconciled: "1")
      settings.update(hide_reconciled: "0")

      expect(budget.reload.read_attribute(:settings)).to eq({})
    end

    it "persists the setting to the database" do
      settings.update(hide_reconciled: "1")

      expect(budget.reload.read_attribute(:settings)).to eq("hide_reconciled" => true)
    end
  end
end
