# frozen_string_literal: true

require "rails_helper"

describe ApplicationHelper do
  describe "#number_to_money" do
    subject { helper.number_to_money(cents) }

    let(:cents)  { 12_345 }
    let(:money)  { instance_double(Money) }
    let(:result) { double }

    before do
      allow(Money).to receive(:from_cents).with(cents).and_return(money)
      allow(helper).to receive(:number_to_currency).with(money).and_return(result)
    end

    it { is_expected.to eq(result) }
  end

  describe "#page_title" do
    subject(:page_title) { helper.page_title }

    context "with a page title" do
      before do
        helper.content_for(:title, "Groceries")
      end

      it "suffixes the page title with the application name" do
        expect(page_title).to eq("Groceries - #{t("title")}")
      end
    end

    context "without a page title" do
      it "returns the application name" do
        expect(page_title).to eq(t("title"))
      end
    end
  end
end
