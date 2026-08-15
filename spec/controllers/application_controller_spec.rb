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

  describe "#block_bots" do
    subject { response }

    before do
      request.headers["User-Agent"] = user_agent

      get :index
    end

    context "when the User-Agent is from a bot" do
      let(:user_agent) { UserAgents::BOT }

      it { is_expected.to have_http_status(:not_found) }
      it { is_expected.to have_attributes(body: be_empty) }
    end

    context "when the User-Agent is from a browser" do
      let(:user_agent) { UserAgents::DESKTOP }

      it { is_expected.to redirect_to(new_session_url) }
    end
  end

  describe "#current_budget" do
    context "when the budget belongs to the current user" do
      let(:budget) { create(:budget, settings: { time_zone: "Asia/Tokyo" }) }

      before do
        sign_in_for(budget)

        get :index, params: { budget_id: budget.id }
      end

      it "applies the budget's time zone" do
        expect(response.body).to eq("Asia/Tokyo")
      end
    end

    context "when the budget belongs to another user" do
      let(:budget) { create(:budget) }

      before do
        sign_in
      end

      it "raises an ActiveRecord::RecordNotFound error" do
        expect { get :index, params: { budget_id: budget.id } }
          .to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "#set_request_variant" do
    let(:budget) { create(:budget) }

    before do
      sign_in_for(budget)

      request.headers["User-Agent"] = user_agent

      get :index, params: { budget_id: budget.id }
    end

    context "when the User-Agent is from a mobile browser" do
      let(:user_agent) { UserAgents::MOBILE }

      it "sets the mobile variant" do
        expect(request.variant).to eq([:mobile])
      end
    end

    context "when the User-Agent is from a desktop browser" do
      let(:user_agent) { UserAgents::DESKTOP }

      it "sets the desktop variant" do
        expect(request.variant).to eq([:desktop])
      end
    end
  end
end
