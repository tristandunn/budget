# frozen_string_literal: true

require "rails_helper"

describe TargetForm, type: :form do
  it { is_expected.to be_a(BaseForm) }

  describe ".from" do
    subject(:form) { described_class.from(category: category) }

    context "when the category has a target" do
      let(:category) do
        build(:category, :subcategory, target_type: :monthly_spending, target_amount: 200_00)
      end

      it do
        expect(form).to have_attributes(
          category:      category,
          target_amount: 200_00,
          target_type:   "monthly_spending"
        )
      end
    end

    context "when the category has no target" do
      let(:category) { build(:category, :subcategory) }

      it { is_expected.to have_attributes(target_amount: nil, target_type: "monthly_spending") }
    end
  end

  describe "#target_amount_input" do
    subject(:input) { form.target_amount_input }

    let(:form) { described_class.new(category: build(:category, :subcategory)) }

    context "when target_amount is positive" do
      before do
        form.target_amount = 200_00
      end

      it { is_expected.to eq("200.00") }
    end

    context "when target_amount is nil" do
      before do
        form.target_amount = nil
      end

      it { is_expected.to be_nil }
    end

    context "when target_amount is zero" do
      before do
        form.target_amount = 0
      end

      it { is_expected.to be_nil }
    end
  end

  describe "#target_amount_input=" do
    subject(:form) { described_class.new(category: build(:category, :subcategory)) }

    before do
      form.target_amount = 100_00
    end

    it "stores a parsed decimal as cents" do
      form.target_amount_input = "200.00"

      expect(form.target_amount).to eq(200_00)
    end

    it "strips formatting characters before parsing" do
      form.target_amount_input = "$1,000.50"

      expect(form.target_amount).to eq(100_050)
    end

    it "clears a previously assigned amount when input is blank" do
      form.target_amount_input = ""

      expect(form.target_amount).to be_nil
    end

    it "clears a previously assigned amount when the input cannot be parsed" do
      form.target_amount_input = "abc"

      expect(form.target_amount).to be_nil
    end
  end

  describe "#update" do
    subject(:update) { form.update }

    let(:category) { create(:category, :subcategory) }

    context "when valid" do
      let(:form) do
        described_class.new(
          category:            category,
          target_amount_input: "200.00",
          target_type:         "monthly_spending"
        )
      end

      it { is_expected.to be(true) }

      it "sets the target type" do
        update

        expect(category.reload.target_type).to eq("monthly_spending")
      end

      it "sets the target amount in cents" do
        update

        expect(category.reload.target_amount).to eq(200_00)
      end
    end

    context "when invalid" do
      let(:form) do
        described_class.new(
          category:            category,
          target_amount_input: "0",
          target_type:         "monthly_spending"
        )
      end

      it { is_expected.to be_nil }

      it "does not update the category" do
        update

        expect(category.reload.target_type).to be_nil
      end

      it "merges a numericality error into the form" do
        update

        expect(form.errors[:target_amount]).to include(t("errors.messages.greater_than", count: 0))
      end
    end

    context "when the amount is blank" do
      let(:form) do
        described_class.new(
          category:            category,
          target_amount_input: "",
          target_type:         "monthly_spending"
        )
      end

      it { is_expected.to be_nil }

      it "merges a presence error into the form" do
        update

        expect(form.errors[:target_amount]).to include(t("errors.messages.blank"))
      end
    end
  end
end
