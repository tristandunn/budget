# frozen_string_literal: true

require "rails_helper"

describe "shared/_picker.html.erb" do
  subject(:html) do
    render "shared/picker", **locals do
      "BLOCK_CONTENT"
    end

    rendered
  end

  let(:locals) { { controller: "example-picker" } }

  it "renders the back button" do
    expect(html).to have_button(t("shared.picker.back"))
  end

  it "wires the back button to the controller" do
    expect(html).to have_css("button[data-action='example-picker#back']")
  end

  it "yields the block inside the scroll region" do
    expect(html).to have_text("BLOCK_CONTENT")
  end

  context "with a placeholder" do
    let(:locals)      { { controller: "example-picker", placeholder: placeholder } }
    let(:placeholder) { "Find an item" }

    it "renders the search input wired to the controller" do
      expect(html).to have_css(
        "input[data-example-picker-target='search']" \
        "[data-action='input->example-picker#filter search->example-picker#filter keydown->example-picker#selectOnKey']"
      )
    end

    it "uses the placeholder as both placeholder and aria-label" do
      expect(html).to have_css(
        "input[data-example-picker-target='search']" \
        "[placeholder='#{placeholder}'][aria-label='#{placeholder}']"
      )
    end
  end

  context "without a placeholder" do
    it "does not render the search input" do
      expect(html).to have_no_css("input[data-example-picker-target='search']")
    end
  end
end
