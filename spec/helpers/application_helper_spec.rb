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
end
