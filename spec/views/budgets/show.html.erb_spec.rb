# frozen_string_literal: true

require "rails_helper"

describe "budgets/show.html.erb" do
  subject(:html) do
    render template: "budgets/show", formats: [:html]

    rendered
  end

  it "renders the header with the current month and year" do
    expect(html).to have_css("h1", text: Date.current.strftime("%B %Y"))
  end
end
