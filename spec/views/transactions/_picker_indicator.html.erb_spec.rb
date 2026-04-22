# frozen_string_literal: true

require "rails_helper"

describe "transactions/_picker_indicator.html.erb" do
  subject(:html) do
    render partial: "transactions/picker_indicator"

    rendered
  end

  it "renders a checkmark svg that is hidden until the group ancestor is aria-selected" do
    expect(html).to have_css(
      "svg.invisible[class~='group-aria-selected:visible']",
      visible: :all
    )
  end
end
