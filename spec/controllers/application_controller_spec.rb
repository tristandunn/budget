# frozen_string_literal: true

require "rails_helper"

describe ApplicationController do
  controller do
    def index
      render plain: Time.zone.name
    end
  end

  it { is_expected.to be_a(ActionController::Base) }

  it "includes the authentication helpers" do
    expect(described_class.ancestors).to include(Authentication)
  end

  describe "#assign_current_budget" do
    subject { response.body }

    let(:budget) { create(:budget, settings: { time_zone: "Asia/Tokyo" }) }

    before do
      get :index, params: { budget_id: budget.id }
    end

    it { is_expected.to eq("Asia/Tokyo") }
  end
end
