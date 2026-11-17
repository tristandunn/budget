# frozen_string_literal: true

require "rails_helper"

describe Middleware::Backdoor do
  subject(:call) { described_class.new(app).call(env) }

  let(:app)    { instance_spy(Proc, call: [200, {}, "OK"]) }
  let(:env)    { ActionDispatch::TestRequest.create(Rack::MockRequest.env_for(path, params: params)).env }
  let(:params) { { user: user.id, other: 2 } }
  let(:path)   { "/" }
  let(:user)   { create(:user) }

  context "with user parameters" do
    it "creates a session for the user" do
      expect { call }.to change { user.sessions.count }.by(1)
    end

    it "sets the signed session token cookie" do
      call

      expect(ActionDispatch::Request.new(env).cookie_jar.signed[:session_token]).to eq(user.sessions.last.token)
    end

    it "removes the user parameter from the query string" do
      call

      expect(env["QUERY_STRING"]).to eq("other=2")
    end

    it "calls the underlying app" do
      expect(call).to eq([200, {}, "OK"])
    end
  end

  context "with user parameters on the sign-in path" do
    let(:params) { { user: user.id } }
    let(:path)   { described_class::SIGN_IN_PATH }

    it "creates a session for the user" do
      expect { call }.to change { user.sessions.count }.by(1)
    end

    it "returns a no-content response" do
      expect(call).to eq([204, {}, []])
    end

    it "does not call the underlying app" do
      call

      expect(app).not_to have_received(:call)
    end
  end

  context "with user parameters via POST to the sign-in path" do
    let(:env)    { ActionDispatch::TestRequest.create(Rack::MockRequest.env_for(path, method: "POST", params: params)).env }
    let(:params) { { user: user.id } }
    let(:path)   { described_class::SIGN_IN_PATH }

    it "creates a session for the user" do
      expect { call }.to change { user.sessions.count }.by(1)
    end

    it "returns a no-content response" do
      expect(call).to eq([204, {}, []])
    end

    it "does not call the underlying app" do
      call

      expect(app).not_to have_received(:call)
    end
  end

  context "with nested user parameters" do
    let(:params) { { user: { email: "a@example.com" } } }

    it "does not create a session" do
      expect { call }.not_to change(Session, :count)
    end
  end

  context "without user parameters" do
    let(:params) { { test: 4 } }

    it "does not create a session" do
      expect { call }.not_to change(Session, :count)
    end

    it "does not change the query string" do
      call

      expect(env["QUERY_STRING"]).to eq("test=4")
    end
  end
end
