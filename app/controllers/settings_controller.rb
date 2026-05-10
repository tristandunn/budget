# frozen_string_literal: true

class SettingsController < ApplicationController
  # Update budget settings.
  def update
    current_budget.settings.update(settings_parameters)

    redirect_back_or_to budget_transactions_path(current_budget)
  end

  private

  # Return the permitted settings parameters.
  #
  # @return [ActionController::Parameters] The permitted settings.
  def settings_parameters
    params.expect(settings: :hide_reconciled)
  end
end
