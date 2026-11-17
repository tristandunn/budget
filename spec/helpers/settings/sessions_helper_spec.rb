# frozen_string_literal: true

require "rails_helper"

describe Settings::SessionsHelper do
  describe "#device_description" do
    subject { helper.device_description(agent) }

    let(:agent)    { "Agent" }
    let(:browser)  { instance_double(Browser::Firefox, full_version: "160.0", name: "Firefox", platform: platform, unknown?: false) }
    let(:platform) { instance_double(Browser::Platform, name: "macOS", unknown?: false) }

    before do
      allow(Browser).to receive(:new).with(agent).and_return(browser)
    end

    context "with a known browser and platform" do
      it { is_expected.to eq("Firefox 160.0 on macOS") }
    end

    context "with a generic platform" do
      let(:platform) { instance_double(Browser::Platform, name: "Generic Linux", unknown?: false) }

      it { is_expected.to eq("Firefox 160.0 on Linux") }
    end

    context "with an unknown platform" do
      let(:platform) { instance_double(Browser::Platform, name: "Unknown", unknown?: true) }

      it { is_expected.to eq("Firefox 160.0") }
    end

    context "with an unknown browser" do
      let(:browser) { instance_double(Browser::Unknown, unknown?: true) }

      it { is_expected.to eq(t("settings.sessions.index.unknown_device")) }
    end

    context "with no agent" do
      let(:agent) { nil }

      before do
        allow(Browser).to receive(:new).with(agent).and_call_original
      end

      it { is_expected.to eq(t("settings.sessions.index.unknown_device")) }
    end
  end
end
