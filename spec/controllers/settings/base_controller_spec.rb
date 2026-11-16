# frozen_string_literal: true

require "rails_helper"

describe Settings::BaseController do
  controller do
    def index
      render plain: "settings"
    end
  end

  it { is_expected.to be_a(ApplicationController) }

  it "uses the settings layout" do
    expect(described_class._layout).to eq("settings")
  end

  describe "#current_budget" do
    before do
      sign_in_as(create(:user))
    end

    it "does not require a current budget" do
      allow(controller).to receive(:current_budget)

      get :index

      expect(controller).not_to have_received(:current_budget)
    end
  end
end
