# frozen_string_literal: true

require "rails_helper"

describe PayeeForm, type: :form do
  it { is_expected.to be_a(BaseForm) }

  describe ".from" do
    subject { described_class.from(payee: payee) }

    let(:payee) { build(:payee, name: "Coffee") }

    it { is_expected.to have_attributes(payee: payee, name: "Coffee") }
  end

  describe "#update" do
    subject(:update) { form.update }

    let(:budget) { create(:budget) }
    let(:payee)  { create(:payee, budget: budget, name: "Old Name") }

    context "when renaming to a unique name" do
      let(:form) { described_class.new(payee: payee, name: "New Name") }

      it { is_expected.to be(true) }

      it "updates the payee name" do
        update

        expect(payee.reload.name).to eq("New Name")
      end
    end

    context "when renaming to a blank name" do
      let(:form) { described_class.new(payee: payee, name: "") }

      it { is_expected.to be_nil }

      it "does not update the payee" do
        update

        expect(payee.reload.name).to eq("Old Name")
      end

      it "merges validation errors into the form" do
        update

        expect(form.errors[:name]).to be_present
      end
    end

    context "when renaming to a name matching another payee" do
      let(:existing) { create(:payee, budget: budget, name: "Target") }
      let(:form)     { described_class.new(payee: payee, name: "Target") }

      let!(:transaction) { create(:transaction, budget: budget, payee: payee) }

      before do
        create(:transaction, budget: budget, payee: existing)
      end

      it { is_expected.to be_truthy }

      it "reassigns the renamed payee's transactions to the existing payee" do
        update

        expect(transaction.reload.payee).to eq(existing)
      end

      it "preserves the existing payee's original transactions" do
        update

        expect(existing.transactions.count).to eq(2)
      end

      it "destroys the renamed payee" do
        update

        expect(Payee.exists?(payee.id)).to be(false)
      end
    end

    context "when renaming to a name matching another payee in a different budget" do
      let(:form)         { described_class.new(payee: payee, name: "Shared") }
      let(:other_budget) { create(:budget) }

      before do
        create(:payee, budget: other_budget, name: "Shared")
      end

      it { is_expected.to be(true) }

      it "renames the payee in place" do
        update

        expect(payee.reload.name).to eq("Shared")
      end
    end

    context "when the name is unchanged" do
      let(:form) { described_class.new(payee: payee, name: "Old Name") }

      it { is_expected.to be(true) }

      it "leaves the payee name unchanged" do
        update

        expect(payee.reload.name).to eq("Old Name")
      end
    end
  end
end
