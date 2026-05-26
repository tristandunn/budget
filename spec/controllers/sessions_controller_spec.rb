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

      it { is_expected.to set_session[:user_id].to(user.id) }
      it { is_expected.to redirect_to(root_url) }
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

        delete :destroy
      end

      it { is_expected.to redirect_to(new_session_url) }

      it "removes the user ID from the session" do
        expect(session[:user_id]).to be_nil
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
