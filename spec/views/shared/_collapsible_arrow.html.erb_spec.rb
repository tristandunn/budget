# frozen_string_literal: true

require "rails_helper"

describe "shared/_collapsible_arrow.html.erb" do
  subject(:html) do
    render partial: "shared/collapsible_arrow"

    rendered
  end

  it "renders the element the collapsible controller targets" do
    expect(html).to have_css("[data-collapsible-arrow]", visible: :all)
  end
end
