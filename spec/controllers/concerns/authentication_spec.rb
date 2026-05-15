# frozen_string_literal: true

require "rails_helper"

describe Authentication do
  let(:controller_class) do
    stub_const("AuthenticationTestController", Class.new(ApplicationController))
  end

  let(:instance) { controller_class.new }

  describe ".included" do
    subject(:helper_methods) { controller_class._helper_methods }

    it "includes signed_in? method" do
      expect(helper_methods).to include(:signed_in?)
    end

    it "includes signed_out? method" do
      expect(helper_methods).to include(:signed_out?)
    end
  end

  describe "#resume_session" do
    let(:user) { build_stubbed(:user) }

    before do
      allow(instance).to receive(:user_from_session).and_return(user)
    end

    it "assigns Current.user" do
      instance.resume_session

      expect(Current.user).to eq(user)
    end

    it "returns the current user without re-fetching when already assigned" do
      Current.user = user

      instance.resume_session

      expect(instance).not_to have_received(:user_from_session)
    end
  end

  describe "#signed_in?" do
    context "with a user present" do
      let(:user) { build_stubbed(:user) }

      before do
        allow(instance).to receive(:resume_session).and_return(user)
      end

      it "returns true" do
        expect(instance).to be_signed_in
      end
    end

    context "with no user present" do
      before do
        allow(instance).to receive(:resume_session).and_return(nil)
      end

      it "returns false" do
        expect(instance).not_to be_signed_in
      end
    end
  end

  describe "#signed_out?" do
    context "with a user present" do
      let(:user) { build_stubbed(:user) }

      before do
        allow(instance).to receive(:resume_session).and_return(user)
      end

      it "returns false" do
        expect(instance).not_to be_signed_out
      end
    end

    context "with no user present" do
      before do
        allow(instance).to receive(:resume_session).and_return(nil)
      end

      it "returns true" do
        expect(instance).to be_signed_out
      end
    end
  end

  describe "#start_new_session_for" do
    let(:session) { {} }
    let(:user)    { build_stubbed(:user) }

    before do
      allow(instance).to receive(:session).and_return(session)

      instance.start_new_session_for(user)
    end

    it "assigns Current.user" do
      expect(Current.user).to eq(user)
    end

    it "stores the user ID in the session" do
      expect(session[:user_id]).to eq(user.id)
    end
  end

  describe "#terminate_session" do
    let(:session) { { user_id: 123 } }
    let(:user)    { build_stubbed(:user) }

    before do
      Current.user = user

      allow(instance).to receive(:session).and_return(session)

      instance.terminate_session
    end

    it "clears Current.user" do
      expect(Current.user).to be_nil
    end

    it "removes the user ID from the session" do
      expect(session[:user_id]).to be_nil
    end
  end

  describe "#user_from_session" do
    context "with a user ID in the session" do
      let(:session) { { user_id: user.id } }
      let(:user)    { build_stubbed(:user) }

      before do
        allow(instance).to receive(:session).and_return(session)

        allow(User).to receive(:find_by).and_return(user)
      end

      it "attempts to find the user" do
        instance.user_from_session

        expect(User).to have_received(:find_by).with(id: session[:user_id])
      end

      it "returns the user" do
        expect(instance.user_from_session).to eq(user)
      end
    end

    context "with no user ID in the session" do
      let(:session) { {} }

      before do
        allow(instance).to receive(:session).and_return(session)

        allow(User).to receive(:find_by)
      end

      it "does not attempt to find the user" do
        instance.user_from_session

        expect(User).not_to have_received(:find_by)
      end

      it "returns nil" do
        expect(instance.user_from_session).to be_nil
      end
    end
  end
end
