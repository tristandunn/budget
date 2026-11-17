# frozen_string_literal: true

require "rails_helper"

describe Settings::PasswordsController do
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

      it "assigns a form for the current user" do
        expect(assigns(:form)).to be_a(PasswordForm).and(have_attributes(user: user))
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
    let(:user) { create(:user, password: "old-password") }

    let(:parameters) do
      {
        password_form: {
          current_password:      "old-password",
          password:              "new-password",
          password_confirmation: "new-password"
        }
      }
    end

    context "when valid" do
      let!(:other_session) { create(:session, user: user) }

      before do
        sign_in_as(user)

        patch :update, params: parameters
      end

      it { is_expected.to redirect_to(account_password_url) }
      it { is_expected.to set_flash[:notice].to(t("settings.passwords.update.success")) }

      it "changes the password" do
        expect(user.reload.authenticate("new-password")).to be_truthy
      end

      it "revokes the other sessions" do
        expect(Session).not_to exist(other_session.id)
      end
    end

    context "when the current password is incorrect" do
      let!(:other_session) { create(:session, user: user) }

      before do
        sign_in_as(user)

        patch :update, params: { password_form: parameters[:password_form].merge(current_password: "wrong") }
      end

      it { is_expected.to respond_with(422) }
      it { is_expected.to render_template(:show) }

      it "does not change the password" do
        expect(user.reload.authenticate("old-password")).to be_truthy
      end

      it "keeps the other sessions" do
        expect(Session).to exist(other_session.id)
      end
    end

    context "when signed out" do
      before do
        patch :update, params: parameters
      end

      it { is_expected.to redirect_to(new_session_url) }
    end
  end
end
