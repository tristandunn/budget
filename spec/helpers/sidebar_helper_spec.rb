# frozen_string_literal: true

require "rails_helper"

describe SidebarHelper do
  describe "#sidebar_account_active?" do
    subject { helper.sidebar_account_active?(account) }

    let(:account) { build_stubbed(:account) }

    before do
      allow(helper).to receive_messages(controller_path: path, params: { account_id: account_id })
    end

    context "when viewing the account's transactions" do
      let(:account_id) { account.id.to_s }
      let(:path)       { "accounts/transactions" }

      it { is_expected.to be(true) }
    end

    context "when viewing a different account's transactions" do
      let(:account_id) { account.id + 1 }
      let(:path)       { "accounts/transactions" }

      it { is_expected.to be(false) }
    end

    context "when on a different page" do
      let(:account_id) { account.id }
      let(:path)       { "transactions" }

      it { is_expected.to be(false) }
    end
  end

  describe "#sidebar_account_class" do
    subject { helper.sidebar_account_class(active: active) }

    context "when active" do
      let(:active) { true }

      it { is_expected.to eq("#{described_class::SIDEBAR_ACCOUNT_CLASSES} bg-indigo-800") }
    end

    context "when inactive" do
      let(:active) { false }

      it { is_expected.to eq("#{described_class::SIDEBAR_ACCOUNT_CLASSES} hover:bg-white/5") }
    end
  end

  describe "#sidebar_item_class" do
    subject { helper.sidebar_item_class(active: active) }

    context "when active" do
      let(:active) { true }

      it { is_expected.to eq("#{described_class::SIDEBAR_ITEM_CLASSES} bg-indigo-800") }
    end

    context "when inactive" do
      let(:active) { false }

      it { is_expected.to eq("#{described_class::SIDEBAR_ITEM_CLASSES} hover:bg-white/5") }
    end
  end
end
