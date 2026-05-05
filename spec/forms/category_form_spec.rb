# frozen_string_literal: true

require "rails_helper"

describe CategoryForm, type: :form do
  it { is_expected.to be_a(BaseForm) }

  describe ".from" do
    subject { described_class.from(category: category) }

    let(:category) { build(:category, :subcategory, name: "Groceries") }

    it { is_expected.to have_attributes(category: category, name: "Groceries") }
  end

  describe "#update" do
    subject(:update) { form.update }

    let(:category) { create(:category, :subcategory) }

    context "when valid" do
      let(:form) { described_class.new(category: category, name: "New Name") }

      it { is_expected.to be(true) }

      it "updates the category name" do
        update

        expect(category.reload.name).to eq("New Name")
      end
    end

    context "when invalid" do
      let(:form) { described_class.new(category: category, name: "") }

      it { is_expected.to be_nil }

      it "does not update the category" do
        update

        expect(category.reload.name).not_to eq("")
      end

      it "merges validation errors into the form" do
        update

        expect(form.errors[:name]).to be_present
      end
    end
  end
end
