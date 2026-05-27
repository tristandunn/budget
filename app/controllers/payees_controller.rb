# frozen_string_literal: true

class PayeesController < ApplicationController
  # Render the list of payees in the budget.
  def index
    @budget = current_budget
    @payees = current_budget.payees.order(:name)
  end

  # Render the payee rename form.
  def edit
    @budget = current_budget
    @payee  = payee
    @form   = PayeeForm.from(payee: payee)
  end

  # Update the payee, renaming it or merging it into an existing payee.
  def update
    @budget = current_budget
    @payee  = payee
    @form   = PayeeForm.new(payee: payee, **form_parameters)

    if @form.update
      if request.format.turbo_stream?
        @payees = current_budget.payees.order(:name)
      else
        redirect_to budget_payees_path(current_budget)
      end
    else
      render :edit, status: :unprocessable_content, formats: [:html]
    end
  end

  # Render the defaults to apply when the payee is selected on a transaction.
  def defaults
    render json: {
      account_id:     payee.previous_account_id.to_s,
      subcategory_id: payee.previous_subcategory_id.to_s
    }
  end

  protected

  # Return the permitted form parameters.
  #
  # @return [Hash] The permitted parameters for the form.
  def form_parameters
    params.expect(payee_form: %i(name)).to_h.symbolize_keys
  end

  # Return the payee for the given id parameter, scoped to the budget.
  #
  # @return [Payee] The requested payee.
  def payee
    @payee ||= current_budget.payees.find(params.expect(:id))
  end
end
