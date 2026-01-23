# frozen_string_literal: true

require "rails_helper"

describe "budgets/show.html.erb" do
  subject(:html) do
    render template: "budgets/show", formats: [:html]

    rendered
  end

  let(:budget)      { category.budget }
  let(:category)    { subcategory.parent }
  let(:subcategory) { create(:category, :subcategory) }

  before do
    assign :budget, budget
  end

  it "renders the header with the current month and year" do
    expect(html).to have_css("h1", text: Date.current.strftime("%B %Y"))
  end

  it "renders the parent categories" do
    expect(html).to have_css("thead th", text: category.name)
  end

  it "renders the subcategories" do
    expect(html).to have_css("tbody th", text: subcategory.name)
  end
end
