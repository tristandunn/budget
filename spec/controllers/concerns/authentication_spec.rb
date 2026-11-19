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

  describe "#access_denied" do
    let(:new_session_url) { "https://example.com/session/new" }

    before do
      allow(instance).to receive(:redirect_to)
      allow(instance).to receive(:new_session_url).and_return(new_session_url)
    end

    it "redirects to new_session_url with a see_other status" do
      instance.access_denied

      expect(instance).to have_received(:redirect_to).with(new_session_url, status: :see_other)
    end
  end

  describe "#authenticate" do
    context "when the session is resumed" do
      let(:user) { build_stubbed(:user) }

      before do
        allow(instance).to receive(:access_denied)
        allow(instance).to receive(:resume_session).and_return(user)
      end

      it "does not call access_denied" do
        instance.authenticate

        expect(instance).not_to have_received(:access_denied)
      end
    end

    context "when the session is not resumed" do
      before do
        allow(instance).to receive(:access_denied)
        allow(instance).to receive(:resume_session).and_return(nil)
      end

      it "calls access_denied" do
        instance.authenticate

        expect(instance).to have_received(:access_denied).with(no_args)
      end
    end
  end

  describe "#resume_session" do
    subject(:resume_session) { instance.resume_session }

    let(:jar) { ActionDispatch::TestRequest.create.cookie_jar }

    before do
      allow(instance).to receive(:cookies).and_return(jar)
    end

    context "with a token for a session" do
      let(:record) { create(:session, updated_at: 2.days.ago) }

      before do
        jar.signed[:session_token] = record.token
      end

      it { is_expected.to eq(record) }

      it "assigns Current.session" do
        resume_session

        expect(Current.session).to eq(record)
      end

      it "touches a session last updated over an hour ago" do
        freeze_time do
          resume_session

          expect(record.reload.updated_at).to eq(Time.current)
        end
      end

      it "keeps the cookie" do
        resume_session

        expect(jar.signed[:session_token]).to eq(record.token)
      end
    end

    context "with a token for a recently updated session" do
      let(:record) { create(:session, updated_at: 5.minutes.ago) }

      before do
        jar.signed[:session_token] = record.token
      end

      it "does not touch the session" do
        expect { resume_session }.not_to(change { record.reload.updated_at })
      end
    end

    context "with a token matching no session" do
      before do
        jar.signed[:session_token] = "missing"
      end

      it { is_expected.to be_nil }
    end

    context "with no token" do
      it { is_expected.to be_nil }
    end

    context "with a session already assigned" do
      let(:existing_session) { build_stubbed(:session) }

      before do
        Current.session = existing_session

        allow(Session).to receive(:includes)
      end

      it { is_expected.to eq(existing_session) }

      it "does not look up the session" do
        resume_session

        expect(Session).not_to have_received(:includes)
      end
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
    let(:jar)        { ActionDispatch::TestRequest.create.cookie_jar }
    let(:user)       { create(:user) }
    let(:user_agent) { "Browser" }

    before do
      allow(instance).to receive(:reset_session)
      allow(instance).to receive_messages(
        cookies: jar,
        request: instance_double(ActionDispatch::Request, remote_ip: "127.0.0.1", user_agent: user_agent)
      )

      instance.start_new_session_for(user)
    end

    it "assigns Current.session" do
      expect(Current.session).to eq(user.sessions.first)
    end

    it "resets the session" do
      expect(instance).to have_received(:reset_session)
    end

    it "creates a session record for the user" do
      expect(user.sessions.count).to eq(1)
    end

    it "records the IP address and user agent" do
      expect(user.sessions.first).to have_attributes(ip_address: "127.0.0.1", user_agent: "Browser")
    end

    it "stores the token in a signed cookie" do
      expect(jar.signed[:session_token]).to eq(user.sessions.first.token)
    end

    context "without a user agent" do
      let(:user_agent) { nil }

      it "records no user agent" do
        expect(user.sessions.first.user_agent).to be_nil
      end
    end

    context "with a user agent longer than the column" do
      let(:user_agent) { "a" * 2000 }

      it "truncates the user agent" do
        expect(user.sessions.first.user_agent.length).to eq(1024)
      end
    end
  end

  describe "#terminate_session" do
    let(:jar)    { ActionDispatch::TestRequest.create.cookie_jar }
    let(:record) { create(:session, user: user) }
    let(:user)   { create(:user) }

    before do
      jar.signed[:session_token] = record.token

      allow(instance).to receive(:reset_session)
      allow(instance).to receive(:cookies).and_return(jar)

      instance.terminate_session
    end

    it "clears Current.session" do
      expect(Current.session).to be_nil
    end

    it "resets the session" do
      expect(instance).to have_received(:reset_session)
    end

    it "destroys the session record" do
      expect(Session.exists?(record.id)).to be(false)
    end

    it "removes the cookie" do
      expect(jar[:session_token]).to be_nil
    end
  end
end
