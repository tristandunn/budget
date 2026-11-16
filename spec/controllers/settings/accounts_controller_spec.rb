# frozen_string_literal: true

require "rails_helper"

describe Settings::AccountsController do
  it { is_expected.to be_a(Settings::BaseController) }

  describe "#show" do
    context "when signed in" do
      let(:user) { create(:user) }

      before do
        sign_in_as(user)

        get :show
      end

      it { is_expected.to respond_with(200) }
      it { is_expected.to render_template(:show) }

      it "assigns the current user" do
        expect(assigns(:user)).to eq(user)
      end
    end

    context "when signed out" do
      before do
        get :show
      end

      it { is_expected.to redirect_to(new_session_url) }
    end
  end

  describe "#update" do
    let(:user) { create(:user, email: "old@example.com") }

    context "when valid" do
      before do
        sign_in_as(user)

        patch :update, params: { user: { email: "new@example.com" } }
      end

      it { is_expected.to respond_with(:see_other) }
      it { is_expected.to redirect_to(account_url) }
      it { is_expected.to set_flash[:notice].to(t("settings.accounts.update.success")) }

      it "changes the e-mail" do
        expect(user.reload.email).to eq("new@example.com")
      end
    end

    context "when invalid" do
      before do
        sign_in_as(user)

        patch :update, params: { user: { email: "invalid" } }
      end

      it { is_expected.to respond_with(422) }
      it { is_expected.to render_template(:show) }

      it "does not change the e-mail" do
        expect(user.reload.email).to eq("old@example.com")
      end
    end

    context "when signed out" do
      before do
        patch :update, params: { user: { email: "new@example.com" } }
      end

      it { is_expected.to redirect_to(new_session_url) }
    end
  end
end
