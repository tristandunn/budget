# frozen_string_literal: true

require "rails_helper"

describe SessionsController do
  it { is_expected.to be_a(ApplicationController) }

  describe "#new" do
    context "when signed out" do
      before do
        get :new
      end

      it { is_expected.to respond_with(:ok) }
      it { is_expected.to render_template(:new) }

      it "assigns a session form" do
        expect(assigns(:form)).to be_a(SessionForm)
      end
    end

    context "when signed in" do
      before do
        sign_in

        get :new
      end

      it { is_expected.to redirect_to(root_url) }
    end
  end

  describe "#create" do
    context "when created successfully" do
      let(:user) { create(:user) }

      before do
        post :create, params: {
          session_form: { email: user.email, password: user.password }
        }
      end

      it { is_expected.to redirect_to(root_url) }

      it "creates a session for the user" do
        expect(user.sessions.count).to eq(1)
      end

      it "stores the session token in a signed cookie" do
        expect(cookies.signed[:session_token]).to eq(user.sessions.first.token)
      end
    end

    context "when not created successfully" do
      let(:email) { generate(:email) }
      let(:form)  { instance_double(SessionForm, valid?: false, errors: {}) }

      before do
        allow(SessionForm).to receive(:new).and_return(form)

        post :create, params: {
          session_form: {
            email:    email,
            password: "invalid"
          }
        }
      end

      it { is_expected.to respond_with(:unprocessable_content) }
      it { is_expected.to render_template(:new) }
      it { is_expected.not_to set_session[:user_id] }

      it "does not create a session" do
        expect(Session.count).to eq(0)
      end

      it "initializes the form with the provided parameters" do
        expect(SessionForm).to have_received(:new).with(email: email, password: "invalid")
      end

      it "assigns the form" do
        expect(assigns(:form)).to eq(form)
      end
    end

    context "when signed in" do
      before do
        sign_in

        post :create
      end

      it { is_expected.to redirect_to(root_url) }
    end
  end

  describe "#destroy" do
    context "when signed in" do
      let(:user) { create(:user) }

      before do
        sign_in_as user

        session[:return_to] = budget_path(create(:budget))

        delete :destroy
      end

      it { is_expected.to redirect_to(new_session_url) }

      it "clears the session" do
        expect(session).to be_empty
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
