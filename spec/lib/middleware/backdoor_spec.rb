# frozen_string_literal: true

require "rails_helper"

describe Middleware::Backdoor do
  subject(:call) { described_class.new(app).call(env) }

  let(:app) { ->(_) { [200, {}, "OK"] } }

  context "with user parameters" do
    let(:env) do
      Rack::MockRequest.env_for("", params: { user: 1, other: 2 })
    end

    it "updates the session to include the parameter values" do
      call

      expect(env["rack.session"]).to eq(user_id: 1)
    end

    it "removes the user parameter from the query string" do
      call

      expect(env["QUERY_STRING"]).to eq("other=2")
    end
  end

  context "without user parameters" do
    let(:env) { Rack::MockRequest.env_for("", params: { test: 4 }) }

    it "does not update the session" do
      call

      expect(env["rack.session"]).to be_nil
    end

    it "does not change the query string" do
      call

      expect(env["QUERY_STRING"]).to eq("test=4")
    end
  end
end
