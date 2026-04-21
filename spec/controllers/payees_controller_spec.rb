# frozen_string_literal: true

require "rails_helper"

describe PayeesController do
  describe "#index" do
    let(:budget) { create(:budget) }

    context "with payees in the budget" do
      let!(:payees) { create_list(:payee, 2, budget: budget) }

      before do
        get :index, params: { budget_id: budget.id }
      end

      it { is_expected.to respond_with(200) }

      it "returns payee names ordered alphabetically" do
        expect(response.parsed_body).to eq(payees.map(&:name).sort)
      end
    end

    context "with no payees" do
      before do
        get :index, params: { budget_id: budget.id }
      end

      it "returns an empty array" do
        expect(response.parsed_body).to eq([])
      end
    end

    context "with payees scoped to the budget" do
      let!(:payee) { create(:payee, budget: budget) }

      before do
        create(:payee)

        get :index, params: { budget_id: budget.id }
      end

      it "only returns payees for the requested budget" do
        expect(response.parsed_body).to eq([payee.name])
      end
    end
  end
end
