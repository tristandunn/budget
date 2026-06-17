# frozen_string_literal: true

require "rails_helper"

describe "layouts/application.html.erb" do
  subject(:html) do
    render template: "layouts/application", formats: [:html]

    rendered
  end

  it "renders the page title" do
    expect(html).to have_title(t("title"))
  end

  it "renders a link to the PWA manifest" do
    expect(html).to have_css("link[rel='manifest'][href='#{pwa_manifest_path(format: :json)}']", visible: :all)
  end

  it "enables morphing for same-URL refreshes" do
    expect(html).to have_css("meta[name='turbo-refresh-method'][content='morph']", visible: :all)
  end

  it "preserves scroll position across refreshes" do
    expect(html).to have_css("meta[name='turbo-refresh-scroll'][content='preserve']", visible: :all)
  end
end
