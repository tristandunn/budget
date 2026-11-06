# frozen_string_literal: true

require "rails_helper"

describe UsersController do
  describe "#edit" do
    context "when signed in" do
      let(:user) { create(:user) }

      before do
        sign_in_as(user)

        get :edit
      end

      it { is_expected.to respond_with(200) }
      it { is_expected.to render_template(:edit) }

      it "assigns the current user" do
        expect(assigns(:user)).to eq(user)
      end
    end

    context "when signed out" do
      before do
        get :edit
      end

      it { is_expected.to redirect_to(new_session_url) }
    end
  end

  describe "#update" do
    let(:budget) { create(:budget) }
    let(:user)   { create(:user, email: "old@example.com") }

    context "when valid with the turbo_stream format" do
      before do
        sign_in_as(user)

        patch :update, params: { user: { email: "new@example.com" } }, format: :turbo_stream
      end

      it { is_expected.to respond_with(200) }
      it { is_expected.to render_template(:update) }

      it "changes the e-mail" do
        expect(user.reload.email).to eq("new@example.com")
      end
    end

    context "when valid with the html format" do
      before do
        sign_in_as(user)

        patch :update, params: { user: { email: "new@example.com" } }
      end

      it { is_expected.to respond_with(:see_other) }
      it { is_expected.to redirect_to(root_url) }

      it "changes the e-mail" do
        expect(user.reload.email).to eq("new@example.com")
      end
    end

    context "when valid with the html format and a referer" do
      before do
        request.headers["Referer"] = budget_transactions_url(budget)

        sign_in_as(user)

        patch :update, params: { user: { email: "new@example.com" } }
      end

      it { is_expected.to redirect_to(budget_transactions_url(budget)) }
    end

    context "when invalid" do
      before do
        sign_in_as(user)

        patch :update, params: { user: { email: "invalid" } }
      end

      it { is_expected.to respond_with(422) }
      it { is_expected.to render_template(:edit) }

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
