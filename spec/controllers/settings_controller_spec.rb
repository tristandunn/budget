# frozen_string_literal: true

require "rails_helper"

describe SettingsController do
  let(:budget) { create(:budget) }

  before do
    sign_in_for(budget)
  end

  it { is_expected.to be_a(ApplicationController) }

  describe "#update" do
    context "when enabling a setting" do
      before do
        patch :update, params: { budget_id: budget.id, settings: { hide_reconciled: "1" } }
      end

      it { is_expected.to respond_with(302) }

      it "enables the setting" do
        expect(budget.reload.settings.hide_reconciled?).to be(true)
      end
    end

    context "when disabling a setting" do
      before do
        budget.settings.update(hide_reconciled: "1")

        patch :update, params: { budget_id: budget.id, settings: { hide_reconciled: "0" } }
      end

      it { is_expected.to respond_with(302) }

      it "removes the setting" do
        expect(budget.reload.settings.hide_reconciled?).to be(false)
      end
    end

    context "with an invalid budget" do
      it "raises an ActiveRecord::RecordNotFound error" do
        expect { patch :update, params: { budget_id: 0, settings: { hide_reconciled: "1" } } }
          .to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
