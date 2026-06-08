# frozen_string_literal: true

require "rails_helper"

describe ToolbarHelper do
  describe "#toolbar_item_class" do
    subject { helper.toolbar_item_class(active: active) }

    context "when active" do
      let(:active) { true }

      it { is_expected.to eq("#{described_class::DEFAULT_CLASSES} text-taupe-800") }
    end

    context "when inactive" do
      let(:active) { false }

      it { is_expected.to eq("#{described_class::DEFAULT_CLASSES} text-taupe-400") }
    end
  end
end
