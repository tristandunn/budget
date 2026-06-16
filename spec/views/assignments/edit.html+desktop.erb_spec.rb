# frozen_string_literal: true

require "rails_helper"

describe "assignments/edit.html+desktop.erb" do
  subject(:html) do
    render template: "assignments/edit", formats: [:html], variants: [:desktop]

    rendered
  end

  let(:budget)               { subcategory.budget }
  let(:subcategory)          { create(:category, :subcategory) }
  let(:subcategory_snapshot) { subcategory.snapshots.for_month(Date.current).first }

  let(:form) do
    AssignmentForm.new(
      budget:      budget,
      date:        Date.current.beginning_of_month,
      subcategory: subcategory
    )
  end

  before do
    assign :budget,               budget
    assign :form,                 form
    assign :subcategory_snapshot, subcategory_snapshot
    assign :subcategory,          subcategory
  end

  it "renders inside a turbo frame" do
    expect(html).to have_css("turbo-frame##{dom_id(subcategory, :assignment)}")
  end

  it "renders the amount field" do
    expect(html).to have_field("assignment_form_amount")
  end

  it "pre-fills the amount with the current assigned value" do
    expect(html).to have_field(
      "assignment_form_amount",
      with: Money.from_cents(subcategory_snapshot.amount_assigned).to_s
    )
  end
end
