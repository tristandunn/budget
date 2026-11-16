# frozen_string_literal: true

require "rails_helper"

describe "layouts/settings.html+desktop.erb" do
  subject(:html) do
    render template: "layouts/settings", formats: [:html], variants: [:desktop]

    rendered
  end

  before do
    stub_template("layouts/application.html.erb" => "<%= content_for(:content) %>")

    view.extend(SidebarHelper)
    view.content_for(:title, "Title")
  end

  it "renders the title as the heading" do
    expect(html).to have_css("main h1", text: "Title")
  end

  it "renders its content inside the application layout" do
    expect(html).to have_css("aside").and(have_css("main"))
  end

  it "renders the view content in the main area" do
    view.view_flow.set(:layout, "VIEW_CONTENT")

    expect(html).to have_css("main", text: "VIEW_CONTENT")
  end

  it "renders a link back to the budget" do
    expect(html).to have_css("aside a[href='#{root_path}']", text: t("settings.navigation.back"))
  end

  it "renders the section navigation" do
    expect(html).to have_css("nav[aria-label='#{t("settings.navigation.label")}']")
  end

  it "does not render a notice without a flash notice" do
    expect(html).to have_no_css("[role='status']")
  end

  context "when on the settings page" do
    before do
      allow(view).to receive(:current_page?).with(account_path).and_return(true)
      allow(view).to receive(:current_page?).with(account_password_path).and_return(false)
    end

    it "marks the settings link as the current page" do
      expect(html).to have_css("nav a[href='#{account_path}'][aria-current='page']",
                               text: t("settings.navigation.settings"))
    end
  end

  context "when on another page" do
    before do
      allow(view).to receive(:current_page?).with(account_path).and_return(false)
      allow(view).to receive(:current_page?).with(account_password_path).and_return(false)
    end

    it "does not mark any link as the current page" do
      expect(html).to have_no_css("nav a[aria-current]")
    end
  end

  context "when on the password page" do
    before do
      allow(view).to receive(:current_page?).with(account_path).and_return(false)
      allow(view).to receive(:current_page?).with(account_password_path).and_return(true)
    end

    it "marks the password link as the current page" do
      expect(html).to have_css(
        "nav a[href='#{account_password_path}'][aria-current='page']",
        text: t("settings.navigation.password")
      )
    end
  end

  context "when there is a flash notice" do
    before do
      flash[:notice] = t("settings.accounts.update.success")
    end

    it "renders the notice" do
      expect(html).to have_css("[role='status']", text: t("settings.accounts.update.success"))
    end
  end
end
