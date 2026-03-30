# frozen_string_literal: true

require "rails_helper"

describe CategoriesController do
  it { is_expected.to be_a(ApplicationController) }

  describe "#edit" do
    let(:budget)      { subcategory.budget }
    let(:subcategory) { create(:category, :subcategory) }

    before do
      get :edit, params: { budget_id: budget.id, id: subcategory.id }
    end

    it { is_expected.to respond_with(200) }
    it { is_expected.to render_template(:edit) }

    it "assigns the budget" do
      expect(assigns(:budget)).to eq(budget)
    end

    it "assigns the category" do
      expect(assigns(:category)).to eq(subcategory)
    end
  end

  describe "#update" do
    context "when valid" do
      let(:budget)      { subcategory.budget }
      let(:subcategory) { create(:category, :subcategory) }

      before do
        patch :update, params: {
          budget_id: budget.id,
          id:        subcategory.id,
          category:  { name: "New Name" }
        }
      end

      it "updates the category name" do
        expect(subcategory.reload.name).to eq("New Name")
      end

      it "redirects to the budget" do
        expect(response).to redirect_to(budget_url(budget))
      end
    end

    context "when invalid" do
      let(:budget)      { subcategory.budget }
      let(:subcategory) { create(:category, :subcategory) }

      before do
        patch :update, params: {
          budget_id: budget.id,
          id:        subcategory.id,
          category:  { name: "" }
        }
      end

      it { is_expected.to respond_with(422) }
      it { is_expected.to render_template(:edit) }

      it "assigns the budget" do
        expect(assigns(:budget)).to eq(budget)
      end

      it "assigns the category" do
        expect(assigns(:category)).to eq(subcategory)
      end
    end
  end
end
