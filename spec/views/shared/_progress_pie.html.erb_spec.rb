# frozen_string_literal: true

require "rails_helper"

describe "shared/_progress_pie.html.erb" do
  subject(:html) do
    render(
      locals:  {
        progress:  progress,
        label:     "Halfway there",
        css_class: "size-8"
      },
      partial: "shared/progress_pie"
    )

    rendered
  end

  let(:funded)   { false }
  let(:progress) { instance_double(TargetProgress, funded?: funded, funded_percentage: 50) }

  it "labels the icon with the given title" do
    expect(html).to have_css("svg title", text: "Halfway there")
  end

  context "when funded" do
    let(:funded) { true }

    it "renders the checkmark and not the progress wedge" do
      expect(html).to have_css("svg path")
        .and(have_no_css("svg circle[stroke-dasharray]"))
    end
  end

  context "when not funded" do
    it "renders the progress wedge sized to the funded percentage and not the checkmark" do
      expect(html).to have_css("svg circle[stroke-dasharray='50 100']")
        .and(have_no_css("svg path"))
    end
  end
end
