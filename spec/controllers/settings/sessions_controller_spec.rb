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

  describe "#destroy" do
    let(:user) { create(:user) }

    context "when revoking another session of the user" do
      let(:other_session) { create(:session, user: user) }

      before do
        sign_in_as(user)

        delete :destroy, params: { id: other_session.id }
      end

      it { is_expected.to redirect_to(account_sessions_path) }
      it { is_expected.to set_flash[:notice].to(t("settings.sessions.destroy.success")) }

      it "destroys the session" do
        expect(Session.exists?(other_session.id)).to be(false)
      end
    end

    context "when revoking the current session" do
      before do
        sign_in_as(user)
      end

      it "does not destroy the session" do
        expect { delete :destroy, params: { id: user.sessions.first.id } }
          .to raise_error(ActiveRecord::RecordNotFound)
          .and(not_change(Session, :count))
      end
    end

    context "when revoking the session of another user" do
      before do
        sign_in_as(user)
      end

      it "does not destroy the session" do
        other_session = create(:session)

        expect { delete :destroy, params: { id: other_session.id } }
          .to raise_error(ActiveRecord::RecordNotFound)
          .and(not_change(Session, :count))
      end
    end

    context "when signed out" do
      before do
        delete :destroy, params: { id: create(:session).id }
      end

      it { is_expected.to redirect_to(new_session_url) }
    end
  end

  describe "#destroy without an ID" do
    let(:user) { create(:user) }

    context "when signed in" do
      let!(:other_session) { create(:session, user: user) }
      let!(:stranger)      { create(:session) }

      before do
        sign_in_as(user)

        delete :destroy
      end

      it { is_expected.to redirect_to(account_sessions_path) }
      it { is_expected.to set_flash[:notice].to(t("settings.sessions.destroy.success_others")) }

      it "destroys the other sessions of the user" do
        expect(Session.exists?(other_session.id)).to be(false)
      end

      it "does not destroy the current session" do
        expect(user.sessions.count).to eq(1)
      end

      it "does not destroy sessions of other users" do
        expect(Session.exists?(stranger.id)).to be(true)
      end
    end

    context "when signed out" do
      before do
        delete :destroy
      end

      it { is_expected.to redirect_to(new_session_url) }
    end
  end
end
