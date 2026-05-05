# frozen_string_literal: true

require "rails_helper"

describe "transactions/_frequency_picker.html.erb" do
  subject(:html) do
    render partial: "transactions/frequency_picker", locals: { form: form }

    rendered
  end

  let(:budget) { build_stubbed(:budget) }
  let(:form)   { TransactionForm.new(budget: budget) }

  it "does not render a search input" do
    expect(html).to have_no_css("input[data-frequency-picker-target='search']")
  end

  it "renders a Never option with an empty value" do
    expect(html).to have_css(
      "li[data-frequency-picker-target='item'][data-value='']",
      text: t("transactions.frequency.labels.never")
    )
  end

  it "renders each frequency option as an item" do
    Transaction.frequencies.each_key do |value|
      label = t("transactions.frequency.labels.#{value}")

      expect(html).to have_css(
        "li[data-frequency-picker-target='item']" \
        "[data-value='#{value}'][data-label='#{label}']",
        text: label
      )
    end
  end

  context "when the form has a frequency selected" do
    let(:form) { TransactionForm.new(budget: budget, frequency: "monthly") }

    it "marks the matching item as selected" do
      expect(html).to have_css(
        "li[data-frequency-picker-target='item'][data-value='monthly'][aria-selected='true']"
      )
    end

    it "does not mark any other item as selected" do
      expect(html).to have_no_css(
        "li[data-frequency-picker-target='item']:not([data-value='monthly'])[aria-selected='true']"
      )
    end
  end

  context "when the form has no frequency selected" do
    it "marks the Never option as selected" do
      expect(html).to have_css(
        "li[data-frequency-picker-target='item'][data-value=''][aria-selected='true']"
      )
    end

    it "does not mark any other item as selected" do
      expect(html).to have_no_css(
        "li[data-frequency-picker-target='item']:not([data-value=''])[aria-selected='true']"
      )
    end
  end
end
