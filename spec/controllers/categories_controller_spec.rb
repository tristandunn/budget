# frozen_string_literal: true

require "rails_helper"

describe CategoriesController do
  it { is_expected.to be_a(ApplicationController) }

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
