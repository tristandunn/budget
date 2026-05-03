# frozen_string_literal: true

require "rails_helper"

describe PayeesController do
  it { is_expected.to be_a(ApplicationController) }

  describe "#previous_category" do
    let(:budget) { create(:budget) }
    let(:payee)  { create(:payee, budget: budget) }

    context "when the payee belongs to the budget" do
      let(:subcategory) { create(:category, :subcategory, budget: budget) }

      before do
        create(:transaction, budget: budget, payee: payee, subcategory: subcategory)

        get :previous_category, params: { budget_id: budget.id, id: payee.id }
      end

      it { is_expected.to respond_with(:ok) }

      it "returns the previous subcategory id" do
        expect(response.parsed_body).to eq("subcategory_id" => subcategory.id.to_s)
      end
    end

    context "when the payee belongs to a different budget" do
      let(:other_budget) { create(:budget) }
      let(:other_payee)  { create(:payee, budget: other_budget) }

      it "raises a record not found error" do
        expect do
          get :previous_category, params: { budget_id: budget.id, id: other_payee.id }
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
