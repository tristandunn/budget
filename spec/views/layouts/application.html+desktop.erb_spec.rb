# frozen_string_literal: true

require "rails_helper"

describe "layouts/application.html+desktop.erb" do
  subject(:html) do
    render template: "layouts/application", formats: [:html], variants: [:desktop]

    rendered
  end

  it "renders the page title" do
    expect(html).to have_title(t("title"))
  end

  it "renders a link to the PWA manifest" do
    expect(html).to have_css("link[rel='manifest'][href='#{pwa_manifest_path(format: :json)}']", visible: :all)
  end

  it "preloads the collapsed sections style" do
    expect(html).to have_css("script", text: "budget:collapsed-sections", visible: :all)
  end

  it "enables morphing for same-URL refreshes" do
    expect(html).to have_css("meta[name='turbo-refresh-method'][content='morph']", visible: :all)
  end

  it "preserves scroll position across refreshes" do
    expect(html).to have_css("meta[name='turbo-refresh-scroll'][content='preserve']", visible: :all)
  end

  context "when no nested layout provides content" do
    before do
      view.view_flow.set(:layout, "VIEW_CONTENT")
    end

    it "renders the view content in the body" do
      expect(html).to have_css("body", text: "VIEW_CONTENT")
    end
  end

  context "when a nested layout provides content" do
    before do
      view.view_flow.set(:layout, "VIEW_CONTENT")
      view.content_for(:content, "NESTED_CONTENT")
    end

    it "renders the nested layout content in the body" do
      expect(html).to have_css("body", text: "NESTED_CONTENT")
    end

    it "does not render the view content directly" do
      expect(html).to have_no_css("body", text: "VIEW_CONTENT")
    end
  end
end
