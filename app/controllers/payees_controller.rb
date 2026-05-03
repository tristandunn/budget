# frozen_string_literal: true

class PayeesController < ApplicationController
  # Render the most recent subcategory used for the payee within the budget.
  def previous_category
    render json: { subcategory_id: payee.previous_subcategory_id.to_s }
  end

  protected

  # Return the payee for the given id parameter, scoped to the budget.
  #
  # @return [Payee] The requested payee.
  def payee
    @payee ||= current_budget.payees.find(params[:id])
  end
end
