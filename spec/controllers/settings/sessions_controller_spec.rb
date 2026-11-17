# frozen_string_literal: true

require "rails_helper"

describe Settings::SessionsController do
  describe "#index" do
    context "when signed in" do
      let(:user) { create(:user) }

      before do
        sign_in_as(user)

        create(:session, user: user)
        create(:session)

        get :index
      end

      it { is_expected.to respond_with(200) }
      it { is_expected.to render_template(:index) }

      it "assigns the sessions of the current user, newest first" do
        expect(assigns(:sessions)).to eq(user.sessions.order(created_at: :desc))
      end
    end

    context "when signed out" do
      before do
        get :index
      end

      it { is_expected.to redirect_to(new_session_url) }
    end
  end
end
