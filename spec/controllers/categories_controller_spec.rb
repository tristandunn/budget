# frozen_string_literal: true

require "rails_helper"

describe CategoriesController do
  it { is_expected.to be_a(ApplicationController) }

  describe "#index" do
    context "with a JSON request and subcategories in the budget" do
      let(:budget)   { create(:budget) }
      let!(:food)    { create(:category, budget: budget, name: "Food", position: 2) }
      let!(:grocery) { create(:category, budget: budget, parent: food, name: "Groceries", position: 2) }
      let!(:rent)    { create(:category, budget: budget, name: "Rent", position: 1) }

      before do
        get :index, params: { budget_id: budget.id, format: :json }
      end

      it { is_expected.to respond_with(200) }

      it "orders subcategories by parent position, then subcategory position" do
        dining       = create(:category, budget: budget, parent: food, name: "Dining", position: 1)
        monthly_rent = create(:category, budget: budget, parent: rent, name: "Monthly Rent", position: 1)

        get :index, params: { budget_id: budget.id, format: :json }

        expect(response.parsed_body).to eq(
          [
            { "id" => monthly_rent.id, "name" => "Monthly Rent", "parent_name" => "Rent" },
            { "id" => dining.id,       "name" => "Dining",       "parent_name" => "Food" },
            { "id" => grocery.id,      "name" => "Groceries",    "parent_name" => "Food" }
          ]
        )
      end
    end

    context "with a JSON request and no categories" do
      let(:budget) { create(:budget) }

      before do
        get :index, params: { budget_id: budget.id, format: :json }
      end

      it { is_expected.to respond_with(200) }

      it "returns an empty array" do
        expect(response.parsed_body).to eq([])
      end
    end

    context "with a JSON request scoped to the budget" do
      let(:budget)       { create(:budget) }
      let(:other_budget) { create(:budget) }

      before do
        create(:category, :subcategory, budget: other_budget)

        get :index, params: { budget_id: budget.id, format: :json }
      end

      it "only returns subcategories belonging to the budget" do
        expect(response.parsed_body).to eq([])
      end
    end

    context "without a budget" do
      it "raises an ActiveRecord::RecordNotFound error" do
        expect do
          get :index, params: { budget_id: 0, format: :json }
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "#edit" do
    let(:budget)      { subcategory.budget }
    let(:form)        { instance_double(CategoryForm) }
    let(:subcategory) { create(:category, :subcategory) }

    before do
      allow(CategoryForm).to receive(:from).and_return(form)

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

    it "initializes the form from the category" do
      expect(CategoryForm).to have_received(:from).with(category: subcategory)
    end

    it "assigns the form" do
      expect(assigns(:form)).to eq(form)
    end
  end

  describe "#update" do
    context "when valid" do
      let(:budget)      { subcategory.budget }
      let(:form)        { instance_double(CategoryForm, update: true) }
      let(:subcategory) { create(:category, :subcategory) }

      before do
        allow(CategoryForm).to receive(:new).and_return(form)

        patch :update, params: {
          budget_id:     budget.id,
          id:            subcategory.id,
          category_form: { name: "New Name" }
        }
      end

      it "initializes the form with the category and parameters" do
        expect(CategoryForm).to have_received(:new).with(category: subcategory, name: "New Name")
      end

      it "updates the category" do
        expect(form).to have_received(:update).with(no_args)
      end

      it "redirects to the budget" do
        expect(response).to redirect_to(budget_url(budget))
      end
    end

    context "when invalid" do
      let(:budget)      { subcategory.budget }
      let(:form)        { instance_double(CategoryForm, update: nil) }
      let(:subcategory) { create(:category, :subcategory) }

      before do
        allow(CategoryForm).to receive(:new).and_return(form)

        patch :update, params: {
          budget_id:     budget.id,
          id:            subcategory.id,
          category_form: { name: "" }
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

      it "assigns the form" do
        expect(assigns(:form)).to eq(form)
      end
    end
  end
end
