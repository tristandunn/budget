# frozen_string_literal: true

require "rails_helper"

describe "pwa/manifest.json.erb" do
  subject(:manifest) { JSON.parse(rendered) }

  before do
    render template: "pwa/manifest", formats: [:json]
  end

  it "renders the localized name" do
    expect(manifest).to include("name" => t("title"))
  end

  it "renders the localized short name" do
    expect(manifest).to include("short_name" => t("title"))
  end

  it "renders the start URL" do
    expect(manifest).to include("start_url" => "/")
  end

  it "renders the standalone display mode" do
    expect(manifest).to include("display" => "standalone")
  end

  it "renders the background color" do
    expect(manifest).to include("background_color" => "#FFF")
  end

  it "renders the theme color" do
    expect(manifest).to include("theme_color" => "#FFF")
  end

  it "renders an empty icons array" do
    expect(manifest).to include("icons" => [])
  end
end
