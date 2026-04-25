# frozen_string_literal: true

require "rails_helper"

describe "transactions/_picker_indicator.html.erb" do
  subject(:html) do
    render partial: "transactions/picker_indicator"

    rendered
  end

  it "hides the checkmark svg until the picker ancestor has a selection" do
    expect(html).to have_css(
      "svg.hidden[class~='group-has-aria-selected/picker:block']",
      visible: :all
    )
  end

  it "keeps the checkmark transparent until the group ancestor is aria-selected" do
    expect(html).to have_css(
      "svg.text-transparent[class~='group-aria-selected:text-indigo-600']",
      visible: :all
    )
  end
end
